import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_practice/repositories/job_photo_repository.dart';
import 'package:flutter_practice/repositories/job_repository.dart';
import 'package:flutter_practice/screens/job_detail_screen.dart';
import 'package:flutter_practice/screens/job_photo_gallery_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JobRepository jobRepo;
  late JobPhotoRepository photoRepo;
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('screen_13_test');
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() {
    jobRepo = JobRepository.instance;
    photoRepo = JobPhotoRepository.instance;
  });

  group('Job Detail (Screen 13) - UI & Layout Tests', () {
    testWidgets('renders Header, Customer Info with actions, and Job Description correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final job = jobRepo.getJobById('#00028')!;

      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(jobId: job.id),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header Card
      expect(find.text('#00028'), findsOneWidget);
      expect(find.text(job.title), findsOneWidget);
      expect(find.text('${job.date} ${job.time} น.'), findsOneWidget);
      expect(find.text(job.priority), findsWidgets);

      // 2. Customer Info Card
      expect(find.text('ข้อมูลลูกค้า'), findsOneWidget);
      expect(find.text(job.client), findsOneWidget);
      expect(find.text('0812345678'), findsOneWidget);
      expect(find.text(job.location), findsOneWidget);
      expect(find.byIcon(Icons.phone_rounded), findsWidgets);
      expect(find.byIcon(Icons.near_me_outlined), findsWidgets);

      // 3. Job Description Card
      expect(find.text('รายละเอียดงาน'), findsWidgets);
      expect(find.text(job.description.isNotEmpty ? job.description : 'เครื่องปรับอากาศไม่เย็น'), findsWidgets);
    });

    testWidgets('empty state displays when no photos exist for job', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Use a job without photos e.g. #00026
      final job = jobRepo.getJobById('#00026')!;
      expect(photoRepo.getPhotosByJobId(job.id), isEmpty);

      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(jobId: job.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('รูปหน้างาน'), findsOneWidget);
      expect(find.text('ยังไม่มีรูปภาพ'), findsOneWidget);
      expect(find.text('กดเพื่อเพิ่มรูปหน้างาน'), findsOneWidget);
      expect(find.text('ดูทั้งหมด'), findsNothing);
      expect(find.text('ถ่ายรูปเพิ่มเติม'), findsNothing);
    });

    testWidgets('photo section renders thumbnails, badges, add photo card and extra photo button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testJobId = '#00024';

      // Clean existing photos for testJobId if any
      final existing = photoRepo.getPhotosByJobId(testJobId);
      for (final p in existing) {
        await photoRepo.deletePhoto(jobId: testJobId, photoId: p.id);
      }

      // Add 2 photos: one ก่อนดำเนินการ, one หลังดำเนินการ
      final file1 = File('${tempDir.path}/test_13_1.png')..writeAsStringSync('1');
      final file2 = File('${tempDir.path}/test_13_2.png')..writeAsStringSync('2');

      await photoRepo.addPhoto(
        jobId: testJobId,
        sourceFile: XFile(file1.path),
        photoType: 'ก่อนดำเนินการ',
        note: 'สภาพก่อนล้างแอร์',
      );
      await photoRepo.addPhoto(
        jobId: testJobId,
        sourceFile: XFile(file2.path),
        photoType: 'หลังดำเนินการ',
        note: 'สภาพหลังล้างแอร์สะอาด',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(jobId: testJobId),
        ),
      );
      await tester.pumpAndSettle();

      // Check header count (2)
      expect(find.text('รูปหน้างาน (2)'), findsOneWidget);
      expect(find.text('ดูทั้งหมด'), findsOneWidget);

      // Check photo type badges
      expect(find.text('ก่อนดำเนินการ'), findsOneWidget);
      expect(find.text('หลังดำเนินการ'), findsOneWidget);

      // Check add photo card in thumbnail list
      expect(find.text('เพิ่มรูป'), findsOneWidget);

      // Check outlined button "ถ่ายรูปเพิ่มเติม"
      expect(find.text('ถ่ายรูปเพิ่มเติม'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });

    testWidgets('tapping thumbnail or ดูทั้งหมด navigates to JobPhotoGalleryScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testJobId = '#00024';

      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(jobId: testJobId),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "ดูทั้งหมด"
      await tester.tap(find.text('ดูทั้งหมด'));
      await tester.pumpAndSettle();

      // Verifies gallery screen is opened
      expect(find.byType(JobPhotoGalleryScreen), findsOneWidget);
      expect(find.text('รูปหน้างาน (2)'), findsOneWidget);

      // Pop back
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(JobDetailScreen), findsOneWidget);
    });

    testWidgets('deleting photo from repo immediately updates thumbnail count and list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testJobId = '#00024';

      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(jobId: testJobId),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('รูปหน้างาน (2)'), findsOneWidget);

      // Delete one photo
      final photos = photoRepo.getPhotosByJobId(testJobId);
      await photoRepo.deletePhoto(jobId: testJobId, photoId: photos.first.id);
      await tester.pumpAndSettle();

      // Automatically refreshed to (1)
      expect(find.text('รูปหน้างาน (1)'), findsOneWidget);
      expect(find.text('หลังดำเนินการ'), findsOneWidget);
    });

    testWidgets('photos do not bleed across different job IDs', (tester) async {
      const jobA = '#00024';
      const jobB = '#00026';

      expect(photoRepo.getPhotosByJobId(jobA).length, equals(1));
      expect(photoRepo.getPhotosByJobId(jobB), isEmpty);
    });

    testWidgets('changing job status retains photos and Job ID intact', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testJobId = '#00024';
      final photosBefore = photoRepo.getPhotosByJobId(testJobId);
      expect(photosBefore.isNotEmpty, isTrue);

      // Update status
      jobRepo.updateJobStatus(testJobId, 'กำลังดำเนินการ', note: 'กำลังเริ่มงาน');

      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(jobId: testJobId),
        ),
      );
      await tester.pumpAndSettle();

      final photosAfter = photoRepo.getPhotosByJobId(testJobId);
      expect(photosAfter.length, equals(photosBefore.length));
      expect(find.text('#00024'), findsOneWidget);
      expect(find.text('รูปหน้างาน (1)'), findsOneWidget);
    });
  });
}
