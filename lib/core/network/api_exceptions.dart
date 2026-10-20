/// คลาสพื้นฐานสำหรับ Error จาก API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException (Status: $statusCode): $message';
}

/// กรณีเชื่อมต่อ Network ไม่ได้ หรือ Timeout
class NetworkException extends ApiException {
  const NetworkException({required super.message, super.statusCode, super.data});
}

/// กรณี 401 Unauthorized (ไม่ได้เข้าสู่ระบบ หรือ Session หมดอายุ)
class UnauthorizedException extends ApiException {
  const UnauthorizedException({required super.message, super.statusCode = 401, super.data});
}

/// กรณี 403 Forbidden (ไม่มีสิทธิ์เข้าถึงหรือดำเนินการ)
class ForbiddenException extends ApiException {
  const ForbiddenException({required super.message, super.statusCode = 403, super.data});
}

/// กรณี 409 Conflict (เปลี่ยนสถานะผิดกฎ State Machine หรือ Optimistic Lock Version ชนกัน)
class ConflictException extends ApiException {
  const ConflictException({required super.message, super.statusCode = 409, super.data});
}

/// กรณี 404 Not Found (ไม่พบข้อมูลงานตาม ID)
class NotFoundException extends ApiException {
  const NotFoundException({required super.message, super.statusCode = 404, super.data});
}

/// กรณี 400 Bad Request (ข้อมูลไม่ผ่านการตรวจสอบ Validation)
class ValidationException extends ApiException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    super.statusCode = 400,
    this.fieldErrors,
    super.data,
  });
}

/// กรณี 500 Internal Server Error
class ServerException extends ApiException {
  const ServerException({required super.message, super.statusCode = 500, super.data});
}
