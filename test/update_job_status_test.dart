import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_practice/models/job.dart';
import 'package:flutter_practice/repositories/job_photo_repository.dart';
import 'package:flutter_practice/repositories/job_repository.dart';
import 'package:flutter_practice/screens/dashboard_screen.dart';
import 'package:flutter_practice/screens/job_detail_screen.dart';
import 'package:flutter_practice/screens/job_list_screen.dart';
import 'package:flutter_practice/screens/update_job_status_screen.dart';

void main() {
  setUp(() {
    JobPhotoRepository.instance.clear();
  });

  group('JobStatus & JobRepository Transition Unit Tests', () {
    test('JobStatus enum mappings and colors', () {
      expect(JobStatus.fromString('รอดำเนินการ'), equals(JobStatus.pending));
      expect(JobStatus.fromString('กำลังดำเนินการ'), equals(JobStatus.inProgress));
      expect(JobStatus.fromString('เสร็จสิ้น'), equals(JobStatus.completed));
      expect(JobStatus.fromString('ยกเลิก'), equals(JobStatus.cancelled));

      expect(JobStatus.pending.label, equals('รอดำเนินการ'));
      expect(JobStatus.cancelled.label, equals('ยกเลิก'));
    });

    test('canTransition strictly enforces status workflow rules', () {
      // 1. จาก "รอดำเนินการ"
      expect(JobRepository.canTransition('รอดำเนินการ', 'กำลังดำเนินการ'), isTrue);
      expect(JobRepository.canTransition('รอดำเนินการ', 'ยกเลิก'), isTrue);
      expect(JobRepository.canTransition('รอดำเนินการ', 'เสร็จสิ้น'), isFalse);
      expect(JobRepository.canTransition('รอดำเนินการ', 'รอดำเนินการ'), isTrue);

      // 2. จาก "กำลังดำเนินการ"
      expect(JobRepository.canTransition('กำลังดำเนินการ', 'เสร็จสิ้น'), isTrue);
      expect(JobRepository.canTransition('กำลังดำเนินการ', 'ยกเลิก'), isTrue);
      expect(JobRepository.canTransition('กำลังดำเนินการ', 'รอดำเนินการ'), isFalse);
      expect(JobRepository.canTransition('กำลังดำเนินการ', 'กำลังดำเนินการ'), isTrue);

      // 3. จาก "เสร็จสิ้น" (สิ้นสุดแล้ว)
      expect(JobRepository.canTransition('เสร็จสิ้น', 'รอดำเนินการ'), isFalse);
      expect(JobRepository.canTransition('เสร็จสิ้น', 'กำลังดำเนินการ'), isFalse);
      expect(JobRepository.canTransition('เสร็จสิ้น', 'ยกเลิก'), isFalse);

      // 4. จาก "ยกเลิก" (สิ้นสุดแล้ว)
      expect(JobRepository.canTransition('ยกเลิก', 'รอดำเนินการ'), isFalse);
      expect(JobRepository.canTransition('ยกเลิก', 'กำลังดำเนินการ'), isFalse);
      expect(JobRepository.canTransition('ยกเลิก', 'เสร็จสิ้น'), isFalse);
    });

    test('updateJobStatus to ยกเลิก updates counts correctly without reducing totalCount', () {
      final repo = JobRepository.instance;
      final initialTotal = repo.totalCount;
      final initialPending = repo.pendingCount;
      final initialCancelled = repo.cancelledCount;

      // หางานที่สถานะ "รอดำเนินการ"
      final targetJob = repo.jobs.firstWhere((j) => j.status == 'รอดำเนินการ');
      final success = repo.updateJobStatus(
        targetJob.id,
        'ยกเลิก',
        note: 'ลูกค้ายกเลิกนัดหมาย',
      );

      expect(success, isTrue);
      final updatedJob = repo.getJobById(targetJob.id);
      expect(updatedJob?.status, equals('ยกเลิก'));
      expect(updatedJob?.statusNote, equals('ลูกค้ายกเลิกนัดหมาย'));

      // สถิติจำนวนงาน
      expect(repo.totalCount, equals(initialTotal)); // totalCount ยังคงเดิม
      expect(repo.pendingCount, equals(initialPending - 1));
      expect(repo.cancelledCount, equals(initialCancelled + 1));
    });
  });

  group('UpdateJobStatusScreen UI & Interaction Tests (หน้าที่ 12)', () {
    testWidgets('renders all 4 status option cards, note field, and action button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: UpdateJobStatusScreen(jobId: '#00028'),
        ),
      );
      await tester.pumpAndSettle();

      // ตรวจสอบ AppBar
      expect(find.text('อัปเดตสถานะงาน'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // ตรวจสอบการ์ดตัวเลือก 4 รายการ
      expect(find.text('รอดำเนินการ'), findsWidgets);
      expect(find.text('งานได้รับการมอบหมายแล้ว'), findsOneWidget);

      expect(find.text('กำลังดำเนินการ'), findsWidgets);
      expect(find.text('เริ่มดำเนินงานหน้างาน'), findsOneWidget);

      expect(find.text('เสร็จสิ้น'), findsWidgets);
      expect(find.text('ดำเนินงานเสร็จสมบูรณ์'), findsOneWidget);

      expect(find.text('ยกเลิก'), findsWidgets);
      expect(find.text('ยกเลิกงาน'), findsOneWidget);

      // ตรวจสอบหมายเหตุ
      expect(find.text('หมายเหตุ (ถ้ามี)'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // ตรวจสอบปุ่ม Action
      expect(find.text('อัปเดตสถานะ'), findsOneWidget);
    });

    testWidgets('selecting new status and typing note enables submit button and shows confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = JobRepository.instance;
      // ให้แน่ใจว่า #00024 อยู่ในสถานะ รอดำเนินการ
      repo.updateJobStatus('#00024', 'รอดำเนินการ');

      await tester.pumpWidget(
        const MaterialApp(
          home: UpdateJobStatusScreen(jobId: '#00024'),
        ),
      );
      await tester.pumpAndSettle();

      // ปุ่มเริ่มต้นยังไม่เปิดใช้งาน (เพราะสถานะยังตรงกับปัจจุบัน และไม่มีหมายเหตุ)
      final submitButtonBefore = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'อัปเดตสถานะ'),
      );
      expect(submitButtonBefore.onPressed, isNull);

      // เลือก "กำลังดำเนินการ"
      await tester.tap(find.text('เริ่มดำเนินงานหน้างาน'));
      await tester.pumpAndSettle();

      // พิมพ์หมายเหตุ
      await tester.enterText(find.byType(TextField), 'เริ่มลงพื้นที่ตรวจเช็คระบบ');
      await tester.pumpAndSettle();

      // ตอนนี้ปุ่มต้องเปิดใช้งานแล้ว
      final submitButtonAfter = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'อัปเดตสถานะ'),
      );
      expect(submitButtonAfter.onPressed, isNotNull);

      // กดปุ่ม "อัปเดตสถานะ"
      await tester.tap(find.widgetWithText(ElevatedButton, 'อัปเดตสถานะ'));
      await tester.pumpAndSettle();

      // ตรวจสอบ Confirmation Dialog
      expect(find.text('ยืนยันการเปลี่ยนสถานะ'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'ยกเลิก'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'ยืนยัน'), findsOneWidget);

      // กดยืนยันใน Dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'ยืนยัน'));
      await tester.pumpAndSettle();

      // ตรวจสอบผลใน Repository
      final updated = repo.getJobById('#00024');
      expect(updated?.status, equals('กำลังดำเนินการ'));
      expect(updated?.statusNote, equals('เริ่มลงพื้นที่ตรวจเช็คระบบ'));
    });

    testWidgets('cancelling dialog does not update status or repository', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = JobRepository.instance;
      repo.updateJobStatus('#00018', 'รอดำเนินการ');

      await tester.pumpWidget(
        const MaterialApp(
          home: UpdateJobStatusScreen(jobId: '#00018'),
        ),
      );
      await tester.pumpAndSettle();

      // เลือก "ยกเลิก"
      await tester.tap(find.text('ยกเลิกงาน'));
      await tester.pumpAndSettle();

      // กดปุ่ม "อัปเดตสถานะ"
      await tester.tap(find.widgetWithText(ElevatedButton, 'อัปเดตสถานะ'));
      await tester.pumpAndSettle();

      expect(find.text('ยืนยันการเปลี่ยนสถานะ'), findsOneWidget);

      // กดยกเลิกใน Dialog (ไม่เปลี่ยนสถานะ)
      await tester.tap(find.widgetWithText(TextButton, 'ยกเลิก'));
      await tester.pumpAndSettle();

      // งานต้องยังเป็น "รอดำเนินการ"
      final job = repo.getJobById('#00018');
      expect(job?.status, equals('รอดำเนินการ'));
    });

    testWidgets('terminal status (เสร็จสิ้น or ยกเลิก) disables status changing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // #00025 มีสถานะ "เสร็จสิ้น"
      await tester.pumpWidget(
        const MaterialApp(
          home: UpdateJobStatusScreen(jobId: '#00025'),
        ),
      );
      await tester.pumpAndSettle();

      // ตรวจสอบข้อความเตือนสถานะสิ้นสุด
      expect(find.textContaining('ซึ่งเป็นสถานะสิ้นสุดแล้ว ไม่สามารถเปลี่ยนแปลงสถานะได้'), findsOneWidget);

      // ปุ่ม "อัปเดตสถานะ" ต้อง Disable
      final submitButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'อัปเดตสถานะ'),
      );
      expect(submitButton.onPressed, isNull);
    });
  });

  group('JobDetailScreen & Cross-Screen Integration Tests', () {
    testWidgets('tapping status badge or edit action navigates to UpdateJobStatusScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(jobId: '#00028'),
        ),
      );
      await tester.pumpAndSettle();

      // ตรวจสอบไอคอนแก้ไขสถานะใน AppBar
      expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);

      // กดไอคอนแก้ไขสถานะ
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();

      // ตรวจสอบว่าเปิดหน้า UpdateJobStatusScreen ขึ้นมา
      expect(find.text('อัปเดตสถานะงาน'), findsOneWidget);
    });

    testWidgets('cancelling a job updates JobDetailScreen, Dashboard, and JobListScreen filter', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = JobRepository.instance;
      final testJobId = '#00012';
      repo.updateJobStatus(testJobId, 'รอดำเนินการ');

      // อัปเดตงานให้เป็น "ยกเลิก"
      repo.updateJobStatus(testJobId, 'ยกเลิก', note: 'ลูกค้าย้ายที่อยู่');

      // 1. ตรวจสอบใน JobDetailScreen
      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(jobId: testJobId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ยกเลิก'), findsWidgets);
      expect(find.text('งานถูกยกเลิกแล้ว'), findsOneWidget);
      expect(find.text('งานนี้ถูกยกเลิกแล้ว'), findsOneWidget);
      expect(find.textContaining('ลูกค้าย้ายที่อยู่'), findsWidgets);

      // 2. ตรวจสอบใน DashboardScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Dashboard ยังคงนับ total jobs ครบถ้วน
      expect(find.text('${repo.totalCount}'), findsWidgets);

      // 3. ตรวจสอบใน JobListScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: JobListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // ตรวจสอบว่ามี Chip "ยกเลิก" และสามารถกดเพื่อกรองได้
      expect(find.textContaining('ยกเลิก ('), findsOneWidget);
      await tester.tap(find.textContaining('ยกเลิก ('));
      await tester.pumpAndSettle();

      // ต้องพบการ์ดงานที่ถูกยกเลิก
      expect(find.text(testJobId), findsOneWidget);
    });
  });
}
