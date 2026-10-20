import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user.dart';

/// ผลลัพธ์จากการเข้าสู่ระบบ
class AuthResult {
  final String accessToken;
  final User user;

  const AuthResult({
    required this.accessToken,
    required this.user,
  });
}

/// Repository สำหรับจัดการระบบยืนยันตัวตน (Authentication)
class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  static AuthRepository get instance => _instance;

  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  AuthRepository._internal({
    ApiClient? apiClient,
    SecureStorageService? secureStorage,
  })  : _apiClient = apiClient ?? ApiClient.instance,
        _secureStorage = secureStorage ?? SecureStorageService.instance;

  /// ดำเนินการ Login ผ่าน POST /api/v1/auth/login
  Future<AuthResult> login(String usernameOrEmail, String password) async {
    // โหมดจำลองข้อมูลสำหรับ Automated Testing เมื่อไม่มี Backend
    if (ApiConfig.useMockMode) {
      return _mockLogin(usernameOrEmail, password);
    }

    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {
          'username': usernameOrEmail.trim(),
          'password': password,
        },
      );

      final responseData = response.data;
      if (responseData is Map && responseData['data'] is Map) {
        final data = responseData['data'] as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String;
        final userData = data['user'] as Map<String, dynamic>;
        final user = User.fromJson(userData);

        // บันทึก JWT ลง Secure Storage และผูกเข้ากับ ApiClient
        await _secureStorage.saveAccessToken(accessToken);
        _apiClient.setAuthToken(accessToken);

        return AuthResult(accessToken: accessToken, user: user);
      } else {
        throw const ServerException(
          message: 'รูปแบบข้อมูลตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// ดึงข้อมูลโปรไฟล์ผู้ใช้ปัจจุบันผ่าน GET /api/v1/auth/me
  Future<User> getMe() async {
    if (ApiConfig.useMockMode) {
      return const User(
        id: 1,
        username: 'admin',
        email: 'admin@serviceflow.com',
        fullName: 'ผู้ดูแลระบบ',
        role: 'ADMIN',
      );
    }

    final response = await _apiClient.get('/auth/me');
    final responseData = response.data;
    if (responseData is Map && responseData['data'] is Map) {
      return User.fromJson(responseData['data'] as Map<String, dynamic>);
    }

    throw const ServerException(
      message: 'ไม่สามารถดึงข้อมูลผู้ใช้งานได้',
    );
  }

  /// กู้คืน Session เดิมจาก Secure Storage
  Future<User?> restoreSession() async {
    try {
      final savedToken = await _secureStorage.getAccessToken();
      if (savedToken == null || savedToken.isEmpty) {
        return null;
      }

      _apiClient.setAuthToken(savedToken);

      if (ApiConfig.useMockMode) {
        return const User(
          id: 1,
          username: 'admin',
          email: 'admin@serviceflow.com',
          fullName: 'ผู้ดูแลระบบ',
          role: 'ADMIN',
        );
      }

      // ตรวจสอบ Token กับเซิร์ฟเวอร์ผ่าน /auth/me
      final user = await getMe();
      return user;
    } catch (e) {
      // หาก Token หมดอายุ หรือไม่ถูกต้อง ให้เคลียร์ทิ้ง
      await logout();
      return null;
    }
  }

  /// ดำเนินการออกจากระบบ ลบ Token ออกจากหน่วยความจำ
  Future<void> logout() async {
    _apiClient.clearAuthToken();
    await _secureStorage.deleteAccessToken();
  }

  /// จำลองการ Login สำหรับ Automated Tests (Mock Mode)
  AuthResult _mockLogin(String usernameOrEmail, String password) {
    final query = usernameOrEmail.trim().toLowerCase();
    if (query == 'admin' || query == 'admin@serviceflow.com') {
      if (password == 'Admin@123456' || password == '123456') {
        const user = User(
          id: 1,
          username: 'admin',
          email: 'admin@serviceflow.com',
          fullName: 'ผู้ดูแลระบบ',
          role: 'ADMIN',
        );
        _apiClient.setAuthToken('mock_admin_token');
        return const AuthResult(accessToken: 'mock_admin_token', user: user);
      }
    } else if (query == 'dispatcher' || query == 'dispatcher@serviceflow.com') {
      if (password == 'Dispatcher@123' || password == '123456') {
        const user = User(
          id: 2,
          username: 'dispatcher',
          email: 'dispatcher@serviceflow.com',
          fullName: 'สมหญิง จัดการดี',
          role: 'DISPATCHER',
        );
        _apiClient.setAuthToken('mock_dispatcher_token');
        return const AuthResult(accessToken: 'mock_dispatcher_token', user: user);
      }
    } else if (query == 'technician' || query == 'technician@serviceflow.com' || query == 'demo@serviceflow.com') {
      if (password == 'Technician@123' || password == '123456') {
        const user = User(
          id: 3,
          username: 'technician',
          email: 'technician@serviceflow.com',
          fullName: 'สมชาย ใจดี',
          role: 'TECHNICIAN',
        );
        _apiClient.setAuthToken('mock_technician_token');
        return const AuthResult(accessToken: 'mock_technician_token', user: user);
      }
    }

    throw const UnauthorizedException(
      message: 'ชื่อผู้ใช้งานหรือรหัสผ่านไม่ถูกต้อง',
      statusCode: 401,
    );
  }
}
