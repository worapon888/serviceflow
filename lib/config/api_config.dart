import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

/// การตั้งค่าเชื่อมต่อ API สำหรับ Development, Staging และ Production
class ApiConfig {
  static const String _defaultAndroidDevUrl = 'http://10.0.2.2:8080/api/v1';
  static const String _defaultLocalhostDevUrl = 'http://localhost:8080/api/v1';
  static const String _defaultStagingUrl = 'https://staging-api.serviceflow.com/api/v1';
  static const String _defaultProductionUrl = 'https://api.serviceflow.com/api/v1';

  /// สภาพแวดล้อมการทำงาน: development, staging, production
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: kReleaseMode ? 'production' : 'development',
  );

  static bool get isProduction => appEnv == 'production';
  static bool get isStaging => appEnv == 'staging';
  static bool get isDevelopment => appEnv == 'development';

  /// ดึง URL หลักของ REST API ตาม Environment และ Platform
  /// - ในโหมด Release: บังคับใช้ HTTPS เสมอ และห้ามใช้ 10.0.2.2
  /// - สามารถระบุ custom URL ผ่าน --dart-define=API_BASE_URL=... ได้
  static String get baseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      if (kReleaseMode && (customUrl.startsWith('http://') || customUrl.contains('10.0.2.2'))) {
        throw StateError(
          'Security Violation: Cleartext HTTP or emulator IP (10.0.2.2) is strictly forbidden in Release builds. '
          'Please specify an HTTPS URL (e.g. --dart-define=API_BASE_URL=https://staging-api.serviceflow.com/api/v1)',
        );
      }
      return customUrl;
    }

    // Release mode defaults by environment
    if (kReleaseMode) {
      if (isStaging) {
        return _defaultStagingUrl;
      }
      return _defaultProductionUrl;
    }

    // Development / Debug mode defaults
    if (isStaging) {
      return _defaultStagingUrl;
    }
    if (isProduction) {
      return _defaultProductionUrl;
    }

    if (kIsWeb) {
      return _defaultLocalhostDevUrl;
    }
    if (Platform.isAndroid) {
      return _defaultAndroidDevUrl;
    }
    return _defaultLocalhostDevUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);

  /// ตรวจสอบว่ากำลังรันในโหมด automated testing (flutter test) หรือไม่
  static bool get isTestEnvironment {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  /// สวิตช์สำหรับ Mock Mode (เปิดเฉพาะเมื่อมี flag USE_MOCK หรือรัน flutter test ที่ไม่มี backend)
  static bool useMockMode =
      const bool.fromEnvironment('USE_MOCK', defaultValue: false) ||
          isTestEnvironment;
}
