/// โมเดลข้อมูลรูปภาพหน้างาน (Job Photo Model)
class JobPhoto {
  final String id;
  final String jobId;
  final String imagePath;
  final String photoType; // 'ก่อนดำเนินการ' หรือ 'หลังดำเนินการ'
  final String note;
  final DateTime createdAt;
  final String? storageKey;
  final String? url;

  const JobPhoto({
    required this.id,
    required this.jobId,
    required this.imagePath,
    required this.photoType,
    this.note = '',
    required this.createdAt,
    this.storageKey,
    this.url,
  });

  /// แปลงข้อความประเภทภาพภาษาไทยเป็น Backend API Enum ('BEFORE' / 'AFTER')
  static String toApiPhotoType(String thaiType) {
    if (thaiType == 'หลังดำเนินการ' || thaiType.toUpperCase() == 'AFTER') {
      return 'AFTER';
    }
    return 'BEFORE';
  }

  /// แปลงประเภทภาพจาก Backend API Enum เป็นข้อความภาษาไทย
  static String toThaiPhotoType(String? apiType) {
    if (apiType == null) return 'ก่อนดำเนินการ';
    final upper = apiType.toUpperCase();
    if (upper == 'AFTER' || apiType == 'หลังดำเนินการ') {
      return 'หลังดำเนินการ';
    }
    return 'ก่อนดำเนินการ';
  }

  JobPhoto copyWith({
    String? id,
    String? jobId,
    String? imagePath,
    String? photoType,
    String? note,
    DateTime? createdAt,
    String? storageKey,
    String? url,
  }) {
    return JobPhoto(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      imagePath: imagePath ?? this.imagePath,
      photoType: photoType ?? this.photoType,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      storageKey: storageKey ?? this.storageKey,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'imagePath': imagePath,
      'photoType': photoType,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'storageKey': storageKey,
      'url': url,
    };
  }

  factory JobPhoto.fromMap(Map<String, dynamic> map) {
    return JobPhoto(
      id: map['id']?.toString() ?? '',
      jobId: map['jobId']?.toString() ?? '',
      imagePath: map['imagePath']?.toString() ?? '',
      photoType: toThaiPhotoType(map['photoType']?.toString()),
      note: map['note']?.toString() ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      storageKey: map['storageKey']?.toString(),
      url: map['url']?.toString(),
    );
  }

  /// แปลง JSON จาก Spring Boot Backend (`ApiResponse<JobPhotoResponse>`)
  factory JobPhoto.fromJson(Map<String, dynamic> json) {
    final rawType = json['photoType']?.toString();
    final thaiType = toThaiPhotoType(rawType);
    final contentUrl = json['url']?.toString() ?? json['imagePath']?.toString() ?? '';

    DateTime parsedDate = DateTime.now();
    if (json['createdAt'] != null) {
      parsedDate = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    }

    return JobPhoto(
      id: json['id']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      imagePath: contentUrl,
      photoType: thaiType,
      note: json['note']?.toString() ?? '',
      createdAt: parsedDate,
      storageKey: json['storageKey']?.toString(),
      url: contentUrl,
    );
  }
}
