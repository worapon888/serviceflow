import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_practice/widgets/photo_source_bottom_sheet.dart';
import 'package:flutter_practice/screens/job_detail_screen.dart';
import 'package:flutter_practice/repositories/job_repository.dart';

void main() {
  group('PhotoSourceBottomSheet Tests', () {
    testWidgets('renders all required UI elements according to Screen 7 prototype', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhotoSourceBottomSheet(),
          ),
        ),
      );

      // Verify Header and Close button
      expect(find.text('เพิ่มรูปหน้างาน'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Verify Option 1: ถ่ายรูป
      expect(find.text('ถ่ายรูป'), findsOneWidget);
      expect(find.text('เปิดกล้องเพื่อถ่ายรูปหน้างาน'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

      // Verify Option 2: เลือกจากแกลเลอรี
      expect(find.text('เลือกจากแกลเลอรี'), findsOneWidget);
      expect(find.text('เลือกรูปจากไฟล์ในเครื่อง'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);

      // Verify Cancel Button
      expect(find.text('ยกเลิก'), findsOneWidget);
    });

    testWidgets('tapping ถ่ายรูป returns ImageSource.camera', (tester) async {
      ImageSource? selectedSource;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedSource = await PhotoSourceBottomSheet.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('เพิ่มรูปหน้างาน'), findsOneWidget);

      await tester.tap(find.text('ถ่ายรูป'));
      await tester.pumpAndSettle();

      expect(selectedSource, equals(ImageSource.camera));
    });

    testWidgets('tapping เลือกจากแกลเลอรี returns ImageSource.gallery', (tester) async {
      ImageSource? selectedSource;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedSource = await PhotoSourceBottomSheet.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('เพิ่มรูปหน้างาน'), findsOneWidget);

      await tester.tap(find.text('เลือกจากแกลเลอรี'));
      await tester.pumpAndSettle();

      expect(selectedSource, equals(ImageSource.gallery));
    });

    testWidgets('tapping ยกเลิก returns null', (tester) async {
      ImageSource? selectedSource = ImageSource.camera;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedSource = await PhotoSourceBottomSheet.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();

      expect(selectedSource, isNull);
    });
  });

  group('JobDetailScreen Photo Section Tests', () {
    testWidgets('renders รูปหน้างาน section with empty state', (tester) async {
      final job = JobRepository.instance.jobs.first;

      await tester.pumpWidget(
        MaterialApp(
          home: JobDetailScreen(jobId: job.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('รูปหน้างาน'), findsOneWidget);
      expect(find.text('ยังไม่มีรูปภาพ'), findsOneWidget);
      expect(find.text('กดเพื่อเพิ่มรูปหน้างาน'), findsOneWidget);
    });
  });
}
