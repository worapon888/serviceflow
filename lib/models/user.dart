/// โมเดลข้อมูลผู้ใช้งาน (User) ในระบบ ServiceFlow
class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String role; // 'ADMIN', 'DISPATCHER', 'TECHNICIAN'
  final bool active;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.active = true,
  });

  /// ตรวจสอบสิทธิ์ผู้ดูแลระบบ
  bool get isAdmin => role == 'ADMIN';

  /// ตรวจสอบสิทธิ์ผู้จัดสรรงาน
  bool get isDispatcher => role == 'DISPATCHER';

  /// ตรวจสอบสิทธิ์ช่างเทคนิค
  bool get isTechnician => role == 'TECHNICIAN';

  /// สิทธิ์ในการสร้างงานใหม่ (ADMIN และ DISPATCHER เท่านั้น)
  bool get canCreateJob => isAdmin || isDispatcher;

  /// สิทธิ์ในการมอบหมายงานให้ช่าง
  bool get canAssignTechnician => isAdmin || isDispatcher;

  /// ข้อความแสดงบทบาทภาษาไทย
  String get roleDisplay {
    switch (role) {
      case 'ADMIN':
        return 'ผู้ดูแลระบบ';
      case 'DISPATCHER':
        return 'ผู้จัดสรรงาน';
      case 'TECHNICIAN':
        return 'ช่างเทคนิค';
      default:
        return role;
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'TECHNICIAN',
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'role': role,
      'active': active,
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? role,
    bool? active,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      active: active ?? this.active,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          email == other.email &&
          role == other.role;

  @override
  int get hashCode => Object.hash(id, username, email, role);

  @override
  String toString() =>
      'User(id: $id, username: $username, fullName: $fullName, role: $role)';
}
