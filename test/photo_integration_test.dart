import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_practice/config/api_config.dart';
import 'package:flutter_practice/controllers/auth_controller.dart';
import 'package:flutter_practice/core/network/api_client.dart';
import 'package:flutter_practice/models/job_photo.dart';
import 'package:flutter_practice/repositories/auth_repository.dart';
import 'package:flutter_practice/repositories/job_photo_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  group('JobPhoto Model & Serialization Tests', () {
    test('JobPhoto.fromJson parses BEFORE photo correctly', () {
      final json = {
        'id': 'photo_1001_abc',
        'jobId': '#00037',
        'photoType': 'BEFORE',
        'note': 'สภาพหน้างานก่อนเริ่มซ่อม',
        'createdAt': '2026-10-19T10:00:00.000Z',
        'url': '/api/v1/jobs/%2300037/photos/photo_1001_abc/content',
        'storageKey': '#00037/uuid1.jpg',
      };

      final photo = JobPhoto.fromJson(json);

      expect(photo.id, 'photo_1001_abc');
      expect(photo.jobId, '#00037');
      expect(photo.photoType, 'ก่อนดำเนินการ');
      expect(photo.note, 'สภาพหน้างานก่อนเริ่มซ่อม');
      expect(photo.url, '/api/v1/jobs/%2300037/photos/photo_1001_abc/content');
      expect(photo.storageKey, '#00037/uuid1.jpg');
      expect(photo.createdAt.year, 2026);
    });

    test('JobPhoto.fromJson parses AFTER photo correctly', () {
      final json = {
        'id': 'photo_1002_def',
        'jobId': '#00037',
        'photoType': 'AFTER',
        'note': 'ซ่อมบำรุงเสร็จสิ้น',
        'createdAt': '2026-10-19T11:30:00.000Z',
        'url': '/api/v1/jobs/%2300037/photos/photo_1002_def/content',
      };

      final photo = JobPhoto.fromJson(json);

      expect(photo.id, 'photo_1002_def');
      expect(photo.photoType, 'หลังดำเนินการ');
      expect(photo.note, 'ซ่อมบำรุงเสร็จสิ้น');
    });

    test('toApiPhotoType and toThaiPhotoType map correctly', () {
      expect(JobPhoto.toApiPhotoType('ก่อนดำเนินการ'), 'BEFORE');
      expect(JobPhoto.toApiPhotoType('หลังดำเนินการ'), 'AFTER');
      expect(JobPhoto.toApiPhotoType('BEFORE'), 'BEFORE');
      expect(JobPhoto.toApiPhotoType('AFTER'), 'AFTER');

      expect(JobPhoto.toThaiPhotoType('BEFORE'), 'ก่อนดำเนินการ');
      expect(JobPhoto.toThaiPhotoType('AFTER'), 'หลังดำเนินการ');
      expect(JobPhoto.toThaiPhotoType('ก่อนดำเนินการ'), 'ก่อนดำเนินการ');
      expect(JobPhoto.toThaiPhotoType('หลังดำเนินการ'), 'หลังดำเนินการ');
    });
  });

  group('JobPhotoRepository In-Memory Unit Tests', () {
    setUp(() {
      ApiConfig.useMockMode = true;
      JobPhotoRepository.instance.clear();
    });

    test('uploadPhoto, getPhotosByJobId, getPhotoBytes, deletePhoto lifecycle', () async {
      final repo = JobPhotoRepository.instance;
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test_upload.jpg')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46]);

      // 1. Upload
      final photo = await repo.uploadPhoto(
        jobId: '#00037',
        sourceFile: XFile(tempFile.path),
        photoType: 'ก่อนดำเนินการ',
        note: 'รูปก่อนซ่อม',
      );

      expect(photo.id, isNotEmpty);
      expect(photo.jobId, '#00037');
      expect(photo.photoType, 'ก่อนดำเนินการ');
      expect(photo.note, 'รูปก่อนซ่อม');

      // 2. Fetch list
      final photos = repo.getPhotosByJobId('#00037');
      expect(photos.length, 1);
      expect(photos.first.id, photo.id);

      // 3. Bytes
      final bytes = await repo.getPhotoBytes('#00037', photo.id);
      expect(bytes, isNotEmpty);

      // 4. Delete
      final deleteSuccess = await repo.deletePhoto(jobId: '#00037', photoId: photo.id);
      expect(deleteSuccess, isTrue);
      expect(repo.getPhotosByJobId('#00037'), isEmpty);
    });

    test('AuthController logout clears JobPhotoRepository cache', () async {
      final repo = JobPhotoRepository.instance;
      repo.setPhotosForTesting('#00037', [
        JobPhoto(
          id: 'p1',
          jobId: '#00037',
          imagePath: '/path/1',
          photoType: 'ก่อนดำเนินการ',
          createdAt: DateTime.now(),
        ),
      ]);

      expect(repo.getPhotosByJobId('#00037').length, 1);

      // Trigger logout
      await AuthController.instance.logout();

      // Repository cache should be cleared
      expect(repo.getPhotosByJobId('#00037'), isEmpty);
    });
  });

  group('JobPhoto Remote API Live Integration Tests (against Spring Boot)', () {
    setUp(() {
      HttpOverrides.global = null;
      ApiConfig.useMockMode = false;
      JobPhotoRepository.instance.clear();
    });

    tearDown(() {
      ApiConfig.useMockMode = true; // reset to mock mode
    });

    test('Technician logs in, uploads photo to #00037, downloads content, and deletes photo', () async {
      final apiClient = ApiClient.instance;

      // 1. Login as technician to obtain valid Bearer token
      final authResult = await AuthRepository.instance.login('technician', 'Technician@123');
      expect(authResult.accessToken, isNotEmpty);
      expect(apiClient.authToken, authResult.accessToken);

      // 2. Prepare a valid JPEG sample file
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/live_test.jpg');
      // Valid minimal JPEG header
      tempFile.writeAsBytesSync([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
        0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
        0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
        0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
        0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
        0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
        0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
        0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
        0x09, 0x0A, 0x0B, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F,
        0x00, 0x7F, 0x00, 0xFF, 0xD9
      ]);

      final repo = JobPhotoRepository.instance;

      // 3. Upload photo to #00028 (assigned to technician)
      final createdPhoto = await repo.uploadPhoto(
        jobId: '#00028',
        sourceFile: XFile(tempFile.path),
        photoType: 'ก่อนดำเนินการ',
        note: 'ภาพก่อนเริ่มซ่อมบำรุง Live Integration Test',
      );

      expect(createdPhoto.id, isNotEmpty);
      expect(createdPhoto.jobId, '#00028');
      expect(createdPhoto.photoType, 'ก่อนดำเนินการ');
      expect(createdPhoto.note, 'ภาพก่อนเริ่มซ่อมบำรุง Live Integration Test');

      // 4. Fetch photos for #00028 from backend
      final photos = await repo.fetchJobPhotos('#00028');
      expect(photos.any((p) => p.id == createdPhoto.id), isTrue);

      // 5. Download binary photo content with Bearer JWT
      final downloadedBytes = await repo.getPhotoBytes('#00028', createdPhoto.id);
      expect(downloadedBytes, isNotEmpty);
      expect(downloadedBytes.length, greaterThan(10));

      // 6. Delete photo
      final deleted = await repo.deletePhoto(
        jobId: '#00028',
        photoId: createdPhoto.id,
      );
      expect(deleted, isTrue);

      // 7. Verify photo is deleted from backend
      final photosAfter = await repo.fetchJobPhotos('#00028');
      expect(photosAfter.any((p) => p.id == createdPhoto.id), isFalse);
    });
  });
}
