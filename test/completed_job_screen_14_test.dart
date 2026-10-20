import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_practice/repositories/job_repository.dart';
import 'package:flutter_practice/screens/completed_job_screen.dart';
import 'package:flutter_practice/screens/job_detail_screen.dart';
import 'package:flutter_practice/screens/job_list_screen.dart';
import 'package:flutter_practice/screens/update_job_status_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JobRepository jobRepo;

  setUp(() {
    jobRepo = JobRepository.instance;
  });

  group('CompletedJobScreen (Screen 14) - UI & Elements Tests', () {
    testWidgets('renders all required elements and animated green check icon', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: CompletedJobScreen(jobId: '#00026'),
        ),
      );

      // Verify animation frames run to completion
      await tester.pumpAndSettle();

      // 1. Success check icon
      expect(find.byKey(const ValueKey('completed_success_icon')), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // 2. Headings & Texts
      expect(find.byKey(const ValueKey('completed_status_title')), findsOneWidget);
      expect(find.text('อัปเดตสถานะสำเร็จ'), findsOneWidget);
      expect(find.byKey(const ValueKey('completed_job_id_text')), findsOneWidget);
      expect(find.text('งาน #00026'), findsOneWidget);
      expect(find.byKey(const ValueKey('completed_job_subtitle')), findsOneWidget);
      expect(find.text('ดำเนินงานเสร็จสิ้นแล้ว'), findsOneWidget);

      // 3. Action Buttons
      expect(find.byKey(const ValueKey('completed_view_details_btn')), findsOneWidget);
      expect(find.text('ดูรายละเอียด'), findsOneWidget);
      expect(find.byKey(const ValueKey('completed_back_to_job_list_btn')), findsOneWidget);
      expect(find.text('กลับหน้ารายการงาน'), findsOneWidget);
    });

    testWidgets('displays correct dynamic Job ID without hardcoding', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: CompletedJobScreen(jobId: '#00019'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('งาน #00019'), findsOneWidget);
    });
  });

  group('CompletedJobScreen (Screen 14) - Navigation Tests', () {
    testWidgets('tap "ดูรายละเอียด" pops back to JobDetailScreen with status completed', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final navKey = GlobalKey<NavigatorState>();

      // Ensure job is inProgress first
      jobRepo.updateJobStatus('#00026', 'กำลังดำเนินการ');

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: JobDetailScreen(jobId: '#00026'),
        ),
      );
      await tester.pumpAndSettle();

      // Push CompletedJobScreen
      navKey.currentState!.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/completed_job'),
          builder: (context) => const CompletedJobScreen(jobId: '#00026'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CompletedJobScreen), findsOneWidget);

      // Update repo status to 'เสร็จสิ้น'
      jobRepo.updateJobStatus('#00026', 'เสร็จสิ้น');

      // Tap "ดูรายละเอียด"
      await tester.tap(find.byKey(const ValueKey('completed_view_details_btn')));
      await tester.pumpAndSettle();

      // CompletedJobScreen should be popped, returning to JobDetailScreen
      expect(find.byType(CompletedJobScreen), findsNothing);
      expect(find.byType(JobDetailScreen), findsOneWidget);
      expect(find.text('#00026'), findsOneWidget);
      expect(find.text('เสร็จสิ้น'), findsWidgets);
    });

    testWidgets('tap "กลับหน้ารายการงาน" returns to JobListScreen cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          initialRoute: '/job_list',
          routes: {
            '/job_list': (context) => const JobListScreen(),
          },
        ),
      );
      await tester.pumpAndSettle();

      navKey.currentState!.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/completed_job'),
          builder: (context) => const CompletedJobScreen(jobId: '#00026'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CompletedJobScreen), findsOneWidget);

      // Tap "กลับหน้ารายการงาน"
      await tester.tap(find.byKey(const ValueKey('completed_back_to_job_list_btn')));
      await tester.pumpAndSettle();

      // Returns to JobListScreen without extra stack
      expect(find.byType(CompletedJobScreen), findsNothing);
      expect(find.byType(JobListScreen), findsOneWidget);
    });
  });

  group('Status Transition & Repository Flow Tests', () {
    testWidgets('flow from UpdateJobStatusScreen: selects เสร็จสิ้น -> confirms -> opens CompletedJobScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Prepare job #00023 as กำลังดำเนินการ
      jobRepo.updateJobStatus('#00023', 'กำลังดำเนินการ');
      final beforeInProgress = jobRepo.inProgressCount;
      final beforeCompleted = jobRepo.completedCount;
      final beforeTotal = jobRepo.totalCount;

      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: JobDetailScreen(jobId: '#00023'),
        ),
      );
      await tester.pumpAndSettle();

      // Open UpdateJobStatusScreen
      navKey.currentState!.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/update_status'),
          builder: (context) => const UpdateJobStatusScreen(jobId: '#00023'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UpdateJobStatusScreen), findsOneWidget);

      // Select 'เสร็จสิ้น'
      await tester.tap(find.text('เสร็จสิ้น').first);
      await tester.pumpAndSettle();

      // Tap 'อัปเดตสถานะ' button
      await tester.tap(find.widgetWithText(ElevatedButton, 'อัปเดตสถานะ'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('ยืนยันการเปลี่ยนสถานะ'), findsOneWidget);

      // Tap 'ยืนยัน'
      await tester.tap(find.widgetWithText(ElevatedButton, 'ยืนยัน'));
      await tester.pumpAndSettle();

      // Must navigate to CompletedJobScreen
      expect(find.byType(CompletedJobScreen), findsOneWidget);
      expect(find.text('งาน #00023'), findsOneWidget);
      expect(find.text('ดำเนินงานเสร็จสิ้นแล้ว'), findsOneWidget);

      // Verify repository counts
      expect(jobRepo.inProgressCount, beforeInProgress - 1);
      expect(jobRepo.completedCount, beforeCompleted + 1);
      expect(jobRepo.totalCount, beforeTotal);
    });

    testWidgets('JobDetailScreen bottom button "เสร็จสิ้นงาน" triggers CompletedJobScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Prepare job #00022 as กำลังดำเนินการ
      jobRepo.updateJobStatus('#00022', 'กำลังดำเนินการ');

      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(jobId: '#00022'),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'เสร็จสิ้นงาน' button at the bottom
      expect(find.text('เสร็จสิ้นงาน'), findsOneWidget);
      await tester.tap(find.text('เสร็จสิ้นงาน'));
      await tester.pumpAndSettle();

      // Confirmation dialog
      expect(find.text('ยืนยันเสร็จสิ้นงาน?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'ยืนยันเสร็จสิ้น'));
      await tester.pumpAndSettle();

      // Must display CompletedJobScreen
      expect(find.byType(CompletedJobScreen), findsOneWidget);
      expect(find.text('งาน #00022'), findsOneWidget);
    });

    test('Repository rule: Terminal status cannot be transitioned', () {
      expect(JobRepository.isTerminalStatus('เสร็จสิ้น'), isTrue);
      expect(JobRepository.isTerminalStatus('ยกเลิก'), isTrue);
      expect(JobRepository.canTransition('เสร็จสิ้น', 'กำลังดำเนินการ'), isFalse);
      expect(JobRepository.canTransition('ยกเลิก', 'กำลังดำเนินการ'), isFalse);
    });
  });
}
