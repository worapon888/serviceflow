import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import 'api_exceptions.dart';

/// HTTP Client สำหรับเรียกใช้งาน ServiceFlow Spring Boot REST API
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  static ApiClient get instance => _instance;

  late final Dio _dio;
  String? _authToken;

  /// Callback เมื่อได้รับ HTTP 401 (Session หมดอายุ)
  VoidCallback? onSessionExpired;

  Dio get dio => _dio;
  String? get authToken => _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Logging & Auth Interceptor สำหรับ Debug Mode และแนบ JWT
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // แนบ Authorization Bearer Token เข้า Protected API ทุกครั้ง
          if (_authToken != null && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }

          if (kDebugMode) {
            debugPrint('🌐 [API Request] ${options.method} ${options.uri}');
            if (options.data != null) {
              final sanitized = _sanitizeData(options.data);
              debugPrint('📦 Payload: $sanitized');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('✅ [API Response] ${response.statusCode} from ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          final statusCode = error.response?.statusCode;
          if (kDebugMode) {
            debugPrint('❌ [API Error] $statusCode: ${error.message}');
            final sanitized = _sanitizeData(error.response?.data);
            debugPrint('❌ Response Body: $sanitized');
          }

          // จัดการ HTTP 401 Session Expired (เฉพาะ Protected Endpoints ไม่รวม /auth/login)
          final path = error.requestOptions.path;
          if (statusCode == 401 && !path.contains('/auth/login')) {
            clearAuthToken();
            onSessionExpired?.call();
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// ป้องกันการพิมพ์รหัสผ่านหรือ Token ลงใน Logs (Security Compliance)
  static dynamic _sanitizeData(dynamic data) {
    if (data is Map) {
      final sanitized = Map<dynamic, dynamic>.from(data);
      for (final key in ['password', 'accessToken', 'token', 'secret', 'refreshToken']) {
        if (sanitized.containsKey(key)) {
          sanitized[key] = '*** [PROTECTED] ***';
        }
      }
      return sanitized;
    }
    return data;
  }

  /// แปลง DioException เป็น Custom ApiException ที่มีชนิดชัดเจน
  ApiException _handleDioError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final responseData = response?.data;

    String errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์';
    if (responseData is Map && responseData.containsKey('message')) {
      errorMessage = responseData['message'].toString();
    } else if (error.message != null && error.message!.isNotEmpty) {
      errorMessage = error.message!;
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkException(
        message: 'ไม่สามารถเชื่อมต่อ Backend ได้ กรุณาตรวจสอบว่าเซิร์ฟเวอร์เปิดอยู่ ($errorMessage)',
        statusCode: statusCode,
        data: responseData,
      );
    }

    switch (statusCode) {
      case 400:
        Map<String, String>? fieldErrors;
        if (responseData is Map && responseData['errors'] is Map) {
          fieldErrors = (responseData['errors'] as Map)
              .map((k, v) => MapEntry(k.toString(), v.toString()));
        }
        return ValidationException(
          message: errorMessage,
          statusCode: 400,
          fieldErrors: fieldErrors,
          data: responseData,
        );
      case 401:
        return UnauthorizedException(
          message: errorMessage,
          statusCode: 401,
          data: responseData,
        );
      case 403:
        return ForbiddenException(
          message: errorMessage,
          statusCode: 403,
          data: responseData,
        );
      case 404:
        return NotFoundException(
          message: errorMessage,
          statusCode: 404,
          data: responseData,
        );
      case 409:
        return ConflictException(
          message: errorMessage,
          statusCode: 409,
          data: responseData,
        );
      case 500:
      default:
        return ServerException(
          message: errorMessage,
          statusCode: statusCode ?? 500,
          data: responseData,
        );
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
