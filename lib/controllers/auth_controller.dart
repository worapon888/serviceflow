import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/job_photo_repository.dart';

/// State Controller สำหรับ Authentication ของ ServiceFlow
/// จัดการ User Profile, Token, สถานะ Loading, และ Session Expiration
class AuthController extends ChangeNotifier {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;
  static AuthController get instance => _instance;

  final AuthRepository _authRepository;
  final ApiClient _apiClient;

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _sessionExpired = false;

  AuthController._internal({
    AuthRepository? authRepository,
    ApiClient? apiClient,
  })  : _authRepository = authRepository ?? AuthRepository.instance,
        _apiClient = apiClient ?? ApiClient.instance {
    // ผูก Callback เมื่อ API คืน 401 Session Expired
    _apiClient.onSessionExpired = _onSessionExpiredFromApi;
  }

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null && _token != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get sessionExpired => _sessionExpired;

  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isDispatcher => _currentUser?.isDispatcher ?? false;
  bool get isTechnician => _currentUser?.isTechnician ?? false;
  bool get canCreateJob => _currentUser?.canCreateJob ?? false;

  /// กู้คืนเซสชันเมื่อเปิดแอปพลิเคชัน
  Future<bool> restoreSession() async {
    _isLoading = true;
    _errorMessage = null;
    _sessionExpired = false;
    notifyListeners();

    try {
      final user = await _authRepository.restoreSession();
      if (user != null) {
        _currentUser = user;
        _token = _apiClient.authToken;
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _currentUser = null;
        _token = null;
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _currentUser = null;
      _token = null;
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// ดำเนินการ Login
  Future<bool> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _sessionExpired = false;
    notifyListeners();

    try {
      final result = await _authRepository.login(usernameOrEmail, password);
      _currentUser = result.user;
      _token = result.accessToken;
      _isLoading = false;
      notifyListeners();
      return true;
    } on UnauthorizedException {
      _errorMessage = 'ชื่อผู้ใช้งานหรือรหัสผ่านไม่ถูกต้อง';
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'ไม่สามารถเข้าสู่ระบบได้ กรุณาลองใหม่อีกครั้ง';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// ดำเนินการ Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.logout();
    } finally {
      JobPhotoRepository.instance.clearCache();
      _currentUser = null;
      _token = null;
      _isLoading = false;
      _errorMessage = null;
      _sessionExpired = false;
      notifyListeners();
    }
  }

  /// จัดการเมื่อ Session หมดอายุ (จาก 401 Interceptor)
  void _onSessionExpiredFromApi() {
    JobPhotoRepository.instance.clearCache();
    _currentUser = null;
    _token = null;
    _sessionExpired = true;
    _errorMessage = 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง';
    notifyListeners();
  }

  /// รีเซ็ตสถานะแจ้งเตือน Session Expired หลังจาก UI นำทางกลับหน้า Login แล้ว
  void clearSessionExpiredNotification() {
    _sessionExpired = false;
    notifyListeners();
  }
}
