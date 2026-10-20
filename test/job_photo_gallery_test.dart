import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_practice/config/api_config.dart';
import 'package:flutter_practice/repositories/job_photo_repository.dart';
import 'package:flutter_practice/repositories/job_repository.dart';
import 'package:flutter_practice/screens/job_detail_screen.dart';
import 'package:flutter_practice/screens/job_photo_gallery_screen.dart';

void main() {
  setUp(() {
    ApiConfig.useMockMode = true;
    JobPhotoRepository.instance.clear();
  });

  group('JobPhotoRepository Gallery & Deletion Tests', () {
    test('getPhotosByJobId with newestFirst orders from newest to oldest', () async {
      final repo = JobPhotoRepository.instance;
      final tempDir = Directory.systemTemp.createTempSync();
      final file1 = File('${tempDir.path}/photo1.png')..writeAsStringSync('1');
      final file2 = File('${tempDir.path}/photo2.png')..writeAsStringSync('2');

      final p1 = await repo.addPhoto(
        jobId: '#00028',
        sourceFile: XFile(file1.path),
        photoType: 'ก่อนดำเนินการ',
      );

      // Delay slightly to ensure different createdAt timestamp
      await Future.delayed(const Duration(milliseconds: 10));

      final p2 = await repo.addPhoto(
        jobId: '#00028',
        sourceFile: XFile(file2.path),
        photoType: 'หลังดำเนินการ',
      );

      final photos = repo.getPhotosByJobId('#00028', newestFirst: true);
      expect(photos.length, equals(2));
      expect(photos.first.id, equals(p2.id));
      expect(photos.last.id, equals(p1.id));
    });

    test('deletePhoto removes photo and isolates by jobId', () async {
      final repo = JobPhotoRepository.instance;
      final tempDir = Directory.systemTemp.createTempSync();
      final file1 = File('${tempDir.path}/job1.png')..writeAsStringSync('job1');
      final file2 = File('${tempDir.path}/job2.png')..writeAsStringSync('job2');

      final p1 = await repo.addPhoto(
        jobId: '#00028',
        sourceFile: XFile(file1.path),
        photoType: 'ก่อนดำเนินการ',
      );

      final p2 = await repo.addPhoto(
        jobId: '#00026',
        sourceFile: XFile(file2.path),
        photoType: 'หลังดำเนินการ',
      );

      // Attempt to delete p2 using wrong jobId should fail and not delete
      final failedDelete = await repo.deletePhoto(jobId: '#00028', photoId: p2.id);
      expect(failedDelete, isFalse);
      expect(repo.getPhotosByJobId('#00026').length, equals(1));

      // Correct deletion of p1
      final successDelete = await repo.deletePhoto(jobId: '#00028', photoId: p1.id);
      expect(successDelete, isTrue);
      expect(repo.getPhotosByJobId('#00028'), isEmpty);
      // Other job's photo is untouched
      expect(repo.getPhotosByJobId('#00026').length, equals(1));
    });
  });

  group('JobPhotoGalleryScreen UI Tests (หน้าที่ 11)', () {
    testWidgets('shows Empty State when no photos exist for the job', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: JobPhotoGalleryScreen(jobId: '#00028'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('รูปหน้างาน (0)'), findsOneWidget);
      expect(find.text('ยังไม่มีรูปภาพ'), findsOneWidget);
      expect(find.text('+ เพิ่มรูป'), findsOneWidget);
    });

    testWidgets('renders photo cards with badges, date, and note', (tester) async {
      final repo = JobPhotoRepository.instance;
      final tempDir = Directory.systemTemp.createTempSync();
      final file1 = File('${tempDir.path}/before.png')..writeAsStringSync('img');
      final file2 = File('${tempDir.path}/after.png')..writeAsStringSync('img');

      await repo.addPhoto(
        jobId: '#00028',
        sourceFile: XFile(file1.path),
        photoType: 'ก่อนดำเนินการ',
        note: 'สภาพก่อนล้าง แอร์ไม่เย็น',
      );

      await repo.addPhoto(
        jobId: '#00028',
        sourceFile: XFile(file2.path),
        photoType: 'หลังดำเนินการ',
        note: 'ล้างทำความสะอาดเรียบร้อย',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: JobPhotoGalleryScreen(jobId: '#00028'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Title shows count 2
      expect(find.text('รูปหน้างาน (2)'), findsOneWidget);

      // Verify badges and notes
      expect(find.text('ก่อนดำเนินการ'), findsOneWidget);
      expect(find.text('สภาพก่อนล้าง แอร์ไม่เย็น'), findsOneWidget);

      expect(find.text('หลังดำเนินการ'), findsOneWidget);
      expect(find.text('ล้างทำความสะอาดเรียบร้อย'), findsOneWidget);

      // Bottom button
      expect(find.text('+ เพิ่มรูป'), findsOneWidget);
    });

    testWidgets('can open photo details modal via three-dot menu', (tester) async {
      final repo = JobPhotoRepository.instance;
      final tempDir = Directory.systemTemp.createTempSync();
      final file = File('${tempDir.path}/single.png')..writeAsStringSync('img');

      await repo.addPhoto(
        jobId: '#00028',
        sourceFile: XFile(file.path),
        photoType: 'ก่อนดำเนินการ',
        note: 'ตรวจสอบฟิลเตอร์',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: JobPhotoGalleryScreen(jobId: '#00028'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap three-dot menu
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      expect(find.text('ดูรายละเอียดรูปภาพ'), findsOneWidget);
      expect(find.text('ลบรูปภาพ'), findsOneWidget);

      // Select ดูรายละเอียดรูปภาพ
      await tester.tap(find.text('ดูรายละเอียดรูปภาพ'));
      await tester.pumpAndSettle();

      expect(find.text('รายละเอียดรูปภาพ'), findsOneWidget);
      expect(find.text('#00028'), findsOneWidget);
      expect(find.text('ดูรูปภาพขนาดเต็ม'), findsOneWidget);
    });

    testWidgets('deleting photo with confirmation removes it from screen and repo', (tester) async {
      final repo = JobPhotoRepository.instance;
      final tempDir = Directory.systemTemp.createTempSync();
      final file = File('${tempDir.path}/to_delete.png')..writeAsStringSync('img');

      await repo.addPhoto(
        jobId: '#00028',
        sourceFile: XFile(file.path),
        photoType: 'ก่อนดำเนินการ',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: JobPhotoGalleryScreen(jobId: '#00028'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('รูปหน้างาน (1)'), findsOneWidget);

      // Tap three dots
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      // Tap ลบรูปภาพ
      await tester.tap(find.text('ลบรูปภาพ'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('ยืนยันการลบรูปภาพ'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.widgetWithText(ElevatedButton, 'ลบรูปภาพ'));
      await tester.pumpAndSettle();

      // Now empty state is displayed and repo is empty
      expect(find.text('รูปหน้างาน (0)'), findsOneWidget);
      expect(find.text('ยังไม่มีรูปภาพ'), findsOneWidget);
      expect(repo.getPhotosByJobId('#00028'), isEmpty);
    });

    testWidgets('tapping photo opens FullscreenPhotoViewer', (tester) async {
      final repo = JobPhotoRepository.instance;
      final tempDir = Directory.systemTemp.createTempSync();
      final file = File('${tempDir.path}/full_test.png')..writeAsStringSync('img');

      await repo.addPhoto(
        jobId: '#00028',
        sourceFile: XFile(file.path),
        photoType: 'หลังดำเนินการ',
        note: 'เสร็จสิ้นสมบูรณ์',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: JobPhotoGalleryScreen(jobId: '#00028'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap the image container
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Verify FullscreenPhotoViewer is opened
      expect(find.byType(FullscreenPhotoViewer), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('หลังดำเนินการ'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      // Returned to gallery
      expect(find.byType(JobPhotoGalleryScreen), findsOneWidget);
    });
  });

  group('JobDetailScreen Gallery Navigation Tests', () {
    testWidgets('tapping ดูทั้งหมด in JobDetailScreen navigates to JobPhotoGalleryScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final job = JobRepository.instance.jobs.first;
      final tempDir = Directory.systemTemp.createTempSync();
      final file = File('${tempDir.path}/nav_test.png')..writeAsStringSync('img');

      await JobPhotoRepository.instance.addPhoto(
        jobId: job.id,
        sourceFile: XFile(file.path),
        photoType: 'ก่อนดำเนินการ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(jobId: job.id),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ดูทั้งหมด'), findsOneWidget);

      // Tap ดูทั้งหมด
      await tester.tap(find.text('ดูทั้งหมด'));
      await tester.pumpAndSettle();

      // Now JobPhotoGalleryScreen is open!
      expect(find.byType(JobPhotoGalleryScreen), findsOneWidget);
      expect(find.text('รูปหน้างาน (1)'), findsOneWidget);
    });
  });
}
