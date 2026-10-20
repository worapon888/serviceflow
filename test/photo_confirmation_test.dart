import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_practice/config/api_config.dart';
import 'package:flutter_practice/repositories/job_photo_repository.dart';
import 'package:flutter_practice/repositories/job_repository.dart';
import 'package:flutter_practice/screens/photo_confirmation_screen.dart';
import 'package:flutter_practice/screens/job_detail_screen.dart';

void main() {
  setUp(() {
    ApiConfig.useMockMode = true;
    JobPhotoRepository.instance.clear();
  });

  group('JobPhotoRepository Tests', () {
    test('addPhoto attaches photo to correct jobId and notifies listeners', () async {
      final repo = JobPhotoRepository.instance;
      int notifications = 0;
      repo.addListener(() => notifications++);

      // Create a dummy temp file
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test_img.png')..writeAsStringSync('dummy content');
      final xFile = XFile(tempFile.path);

      final photo = await repo.addPhoto(
        jobId: '#00028',
        sourceFile: xFile,
        photoType: 'ก่อนดำเนินการ',
        note: 'แอร์มีฝุ่นเกาะหนา',
      );

      expect(photo.jobId, equals('#00028'));
      expect(photo.photoType, equals('ก่อนดำเนินการ'));
      expect(photo.note, equals('แอร์มีฝุ่นเกาะหนา'));
      expect(notifications, equals(1));

      expect(repo.getPhotosByJobId('#00028').length, equals(1));
      expect(repo.getPhotosByJobId('#00026').length, equals(0));
      expect(repo.getPhotoCountByJobId('#00028'), equals(1));
    });
  });

  group('PhotoConfirmationScreen Tests (หน้าที่ 9)', () {
    testWidgets('renders all UI components according to Screen 9 prototype', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/confirm_test.png')..writeAsStringSync('content');
      final xFile = XFile(tempFile.path);

      await tester.pumpWidget(
        MaterialApp(
          home: PhotoConfirmationScreen(
            jobId: '#00028',
            imageFile: xFile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('ตัวอย่างรูปภาพ'), findsOneWidget);
      // Verify Image badge
      expect(find.text('1/1'), findsOneWidget);
      // Verify Photo Type options
      expect(find.text('ประเภทภาพ *'), findsOneWidget);
      expect(find.text('ก่อนดำเนินการ'), findsOneWidget);
      expect(find.text('หลังดำเนินการ'), findsOneWidget);
      // Verify Note field
      expect(find.text('หมายเหตุ'), findsOneWidget);
      expect(find.text('ระบุรายละเอียดเกี่ยวกับรูปภาพ'), findsOneWidget);
      // Verify Save button
      expect(find.text('บันทึกรูปภาพ'), findsOneWidget);
    });

    testWidgets('can switch photo type from ก่อนดำเนินการ to หลังดำเนินการ', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/type_test.png')..writeAsStringSync('content');
      final xFile = XFile(tempFile.path);

      await tester.pumpWidget(
        MaterialApp(
          home: PhotoConfirmationScreen(
            jobId: '#00028',
            imageFile: xFile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap หลังดำเนินการ
      await tester.tap(find.text('หลังดำเนินการ'));
      await tester.pumpAndSettle();

      // Enter Note
      await tester.enterText(find.byType(TextField), 'ล้างแอร์สะอาดเรียบร้อย');
      await tester.pumpAndSettle();

      expect(find.text('ล้างแอร์สะอาดเรียบร้อย'), findsOneWidget);

      // Save photo
      await tester.tap(find.text('บันทึกรูปภาพ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify photo saved to JobPhotoRepository
      final photos = JobPhotoRepository.instance.getPhotosByJobId('#00028');
      expect(photos.length, equals(1));
      expect(photos.first.photoType, equals('หลังดำเนินการ'));
      expect(photos.first.note, equals('ล้างแอร์สะอาดเรียบร้อย'));
    });

    testWidgets('canceling without saving does not add photo to repository', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/cancel_test.png')..writeAsStringSync('content');
      final xFile = XFile(tempFile.path);

      await tester.pumpWidget(
        MaterialApp(
          home: PhotoConfirmationScreen(
            jobId: '#00028',
            imageFile: xFile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pop screen without clicking Save
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(JobPhotoRepository.instance.getPhotosByJobId('#00028'), isEmpty);
    });
  });

  group('JobDetailScreen Photo Thumbnail Integration Tests', () {
    testWidgets('updates from empty state to thumbnails when photos exist', (tester) async {
      final job = JobRepository.instance.jobs.first;

      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(jobId: job.id),
        ),
      );
      await tester.pumpAndSettle();

      // Initially empty
      expect(find.text('รูปหน้างาน'), findsOneWidget);
      expect(find.text('ยังไม่มีรูปภาพ'), findsOneWidget);

      // Add a photo to this job
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/detail_test.png')..writeAsStringSync('content');
      await JobPhotoRepository.instance.addPhoto(
        jobId: job.id,
        sourceFile: XFile(tempFile.path),
        photoType: 'ก่อนดำเนินการ',
      );
      await tester.pumpAndSettle();

      // Now shows count and thumbnail action
      expect(find.text('รูปหน้างาน (1)'), findsOneWidget);
      expect(find.text('ก่อนดำเนินการ'), findsOneWidget);
      expect(find.text('เพิ่มรูป'), findsOneWidget);
      expect(find.text('ถ่ายรูปเพิ่มเติม'), findsOneWidget);
    });
  });
}
