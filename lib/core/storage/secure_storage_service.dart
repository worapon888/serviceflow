import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// บริการจัดเก็บข้อมูลสำคัญ (Secure Storage) ด้วยการเข้ารหัส
/// ใช้สำหรับจัดเก็บ JWT Access Token อย่างปลอดภัย
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  static SecureStorageService get instance => _instance;

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'sf_access_token';

  SecureStorageService._internal({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// บันทึก JWT Access Token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// ดึง JWT Access Token ที่บันทึกไว้
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// ลบ JWT Access Token ออกจากหน่วยความจำปลอดภัย
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  /// ล้างข้อมูลทั้งหมดใน Secure Storage
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
