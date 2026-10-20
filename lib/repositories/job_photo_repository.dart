import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import '../models/job_photo.dart';

/// Repository สำหรับจัดการรูปภาพหน้างาน (Job Photo Repository)
/// เชื่อมต่อกับ Spring Boot REST API ผ่าน ApiClient พร้อมระบบ In-Memory Cache
/// สำหรับรูปภาพและไบต์ของภาพ เพื่อประสิทธิภาพสูงสุด
class JobPhotoRepository extends ChangeNotifier {
  static final JobPhotoRepository instance = JobPhotoRepository._internal();
  factory JobPhotoRepository() => instance;

  final ApiClient _apiClient;

  // แคชเก็บรายการรูปภาพแยกตาม Job ID
  final Map<String, List<JobPhoto>> _photosByJob = {};

  // แคชเก็บข้อมูลไบต์ของรูปภาพ (ป้องกันการโหลดซ้ำ)
  final Map<String, Uint8List> _bytesCache = {};
  static const int _maxCachedImages = 60;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  JobPhotoRepository._internal({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  /// ดึงรายการรูปภาพทั้งหมดของ Job ID นั้นๆ จากแคชในหน่วยความจำ
  /// [newestFirst]: หากเป็น true จะเรียงจากรูปที่สร้างล่าสุดไปหารูปแรก
  List<JobPhoto> getPhotosByJobId(String jobId, {bool newestFirst = false}) {
    final list = List<JobPhoto>.from(_photosByJob[jobId] ?? []);
    if (newestFirst) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  /// นับจำนวนรูปภาพของ Job ID
  int getPhotoCountByJobId(String jobId) {
    return (_photosByJob[jobId] ?? []).length;
  }

  /// ดึงรายการรูปภาพจาก Backend API: GET /api/v1/jobs/{jobId}/photos
  Future<List<JobPhoto>> fetchJobPhotos(String jobId) async {
    _isLoading = true;
    _errorMessage = null;

    if (ApiConfig.useMockMode) {
      _isLoading = false;
      final cached = _photosByJob[jobId] ?? [];
      notifyListeners();
      return cached;
    }

    final encodedJobId = Uri.encodeComponent(jobId);
    try {
      final response = await _apiClient.get('/jobs/$encodedJobId/photos');
      final dynamic rawData = response.data;

      List<dynamic> items = [];
      if (rawData is Map && rawData['data'] is List) {
        items = rawData['data'] as List;
      } else if (rawData is List) {
        items = rawData;
      }

      final photos = items
          .map((item) => JobPhoto.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      // จัดเก็บลงแคช
      _photosByJob[jobId] = photos;
      _isLoading = false;
      notifyListeners();
      return photos;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return _photosByJob[jobId] ?? [];
    } catch (e) {
      _errorMessage = 'ไม่สามารถโหลดรูปภาพได้: $e';
      _isLoading = false;
      notifyListeners();
      return _photosByJob[jobId] ?? [];
    }
  }

  static int _mockCounter = 0;

  /// อัปโหลดรูปภาพใหม่เข้าสู่ Backend API: POST /api/v1/jobs/{jobId}/photos
  Future<JobPhoto> uploadPhoto({
    required String jobId,
    required XFile sourceFile,
    required String photoType,
    String note = '',
  }) async {
    _isLoading = true;
    if (ApiConfig.useMockMode) {
      _mockCounter++;
      final mockPhoto = JobPhoto(
        id: 'photo_${DateTime.now().millisecondsSinceEpoch}_$_mockCounter',
        jobId: jobId,
        imagePath: sourceFile.path,
        photoType: JobPhoto.toThaiPhotoType(photoType),
        note: note.trim(),
        createdAt: DateTime.now(),
      );

      final currentList = _photosByJob[jobId] ?? [];
      currentList.add(mockPhoto);
      _photosByJob[jobId] = currentList;

      _isLoading = false;
      notifyListeners();
      return mockPhoto;
    }

    final bytes = await sourceFile.readAsBytes();

    final encodedJobId = Uri.encodeComponent(jobId);
    final apiPhotoType = JobPhoto.toApiPhotoType(photoType);

    try {
      MultipartFile multipartFile;
      if (!kIsWeb && sourceFile.path.isNotEmpty && File(sourceFile.path).existsSync()) {
        multipartFile = await MultipartFile.fromFile(
          sourceFile.path,
          filename: sourceFile.name.isNotEmpty ? sourceFile.name : 'photo.jpg',
        );
      } else {
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: sourceFile.name.isNotEmpty ? sourceFile.name : 'photo.jpg',
        );
      }

      final formData = FormData.fromMap({
        'image': multipartFile,
        'photoType': apiPhotoType,
        'note': note.trim(),
      });

      final response = await _apiClient.post(
        '/jobs/$encodedJobId/photos',
        data: formData,
      );

      final dynamic responseData = response.data;
      Map<String, dynamic> photoMap = {};
      if (responseData is Map && responseData['data'] is Map) {
        photoMap = Map<String, dynamic>.from(responseData['data'] as Map);
      } else if (responseData is Map) {
        photoMap = Map<String, dynamic>.from(responseData);
      }

      final createdPhoto = JobPhoto.fromJson(photoMap);

      // แคชรูปภาพและไบต์ไว้ในหน่วยความจำทันที ไม่ต้องดาวน์โหลดซ้ำ
      _putBytesCache(createdPhoto.id, bytes);

      final currentList = _photosByJob[jobId] ?? [];
      currentList.removeWhere((p) => p.id == createdPhoto.id);
      currentList.insert(0, createdPhoto);
      _photosByJob[jobId] = currentList;

      _isLoading = false;
      notifyListeners();
      return createdPhoto;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = 'เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// ดึงข้อมูลไบต์ของภาพจาก Backend API: GET /api/v1/jobs/{jobId}/photos/{photoId}/content
  /// พร้อมแนบ Authorization Bearer Header ผ่าน ApiClient
  Future<Uint8List> getPhotoBytes(String jobId, String photoId) async {
    // 1. ตรวจสอบใน Memory Cache
    if (_bytesCache.containsKey(photoId)) {
      return _bytesCache[photoId]!;
    }

    if (ApiConfig.useMockMode) {
      // 1x1 transparent pixel png bytes fallback in test
      final fallback = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
      ]);
      _putBytesCache(photoId, fallback);
      return fallback;
    }

    // 2. เรียกผ่าน API
    final encodedJobId = Uri.encodeComponent(jobId);
    try {
      final response = await _apiClient.get<List<int>>(
        '/jobs/$encodedJobId/photos/$photoId/content',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = Uint8List.fromList(response.data ?? []);
      _putBytesCache(photoId, bytes);
      return bytes;
    } catch (e) {
      debugPrint('Error loading photo content for $photoId: $e');
      rethrow;
    }
  }

  /// ตรวจสอบว่ามีไบต์ในแคชแล้วหรือไม่
  Uint8List? getCachedBytes(String photoId) {
    return _bytesCache[photoId];
  }

  /// ลบรูปภาพผ่าน Backend API: DELETE /api/v1/jobs/{jobId}/photos/{photoId}
  Future<bool> deletePhoto({required String jobId, required String photoId}) async {
    _isLoading = true;
    _errorMessage = null;

    if (ApiConfig.useMockMode) {
      if (_photosByJob.containsKey(jobId)) {
        final list = _photosByJob[jobId]!;
        final idx = list.indexWhere((p) => p.id == photoId);
        if (idx == -1) {
          _isLoading = false;
          notifyListeners();
          return false;
        }
        list.removeAt(idx);
        _bytesCache.remove(photoId);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final encodedJobId = Uri.encodeComponent(jobId);
    try {
      await _apiClient.delete('/jobs/$encodedJobId/photos/$photoId');

      // ลบออกจากแคชรายการภาพ
      if (_photosByJob.containsKey(jobId)) {
        _photosByJob[jobId]!.removeWhere((p) => p.id == photoId);
      }

      // ลบออกจากแคชไบต์
      _bytesCache.remove(photoId);

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'เกิดข้อผิดพลาดในการลบรูปภาพ: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// บันทึกรูปภาพใหม่เข้ากับ Job ID (คงไว้เพื่อ Backward Compatibility)
  Future<JobPhoto> addPhoto({
    required String jobId,
    required XFile sourceFile,
    required String photoType,
    String note = '',
  }) async {
    return await uploadPhoto(
      jobId: jobId,
      sourceFile: sourceFile,
      photoType: photoType,
      note: note,
    );
  }

  /// ลบรูปภาพ (เพื่อรองรับโค้ดเดิม)
  void removePhoto(String photoId) {
    _bytesCache.remove(photoId);
    for (final list in _photosByJob.values) {
      list.removeWhere((p) => p.id == photoId);
    }
    notifyListeners();
  }

  /// จัดการขนาดแคชไบต์ของภาพแบบ FIFO
  void _putBytesCache(String photoId, Uint8List bytes) {
    if (_bytesCache.length >= _maxCachedImages) {
      _bytesCache.remove(_bytesCache.keys.first);
    }
    _bytesCache[photoId] = bytes;
  }

  /// ล้างแคชทั้งหมด (เรียกเมื่อผู้ใช้ Logout)
  void clearCache() {
    _photosByJob.clear();
    _bytesCache.clear();
    _errorMessage = null;
    notifyListeners();
  }

  /// สำหรับล้างข้อมูลในการทดสอบ (Testing)
  @visibleForTesting
  void clear() {
    clearCache();
  }

  /// ใส่รูปในแคชสำหรับการทดสอบ
  @visibleForTesting
  void setPhotosForTesting(String jobId, List<JobPhoto> photos) {
    _photosByJob[jobId] = List.from(photos);
    notifyListeners();
  }
}
