import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_practice/controllers/auth_controller.dart';
import 'package:flutter_practice/models/user.dart';
import 'package:flutter_practice/screens/dashboard_screen.dart';
import 'package:flutter_practice/screens/login_screen.dart';
import 'package:flutter_practice/widgets/custom_bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('User Model Tests', () {
    test('User model deserializes JSON and role permissions correctly', () {
      final admin = User.fromJson({
        'id': 1,
        'username': 'admin',
        'email': 'admin@serviceflow.com',
        'fullName': 'ผู้ดูแลระบบ',
        'role': 'ADMIN',
        'active': true,
      });

      expect(admin.isAdmin, isTrue);
      expect(admin.isDispatcher, isFalse);
      expect(admin.isTechnician, isFalse);
      expect(admin.canCreateJob, isTrue);
      expect(admin.roleDisplay, 'ผู้ดูแลระบบ');

      final dispatcher = User.fromJson({
        'id': 2,
        'username': 'dispatcher',
        'email': 'dispatcher@serviceflow.com',
        'fullName': 'สมหญิง จัดการดี',
        'role': 'DISPATCHER',
        'active': true,
      });

      expect(dispatcher.isAdmin, isFalse);
      expect(dispatcher.isDispatcher, isTrue);
      expect(dispatcher.isTechnician, isFalse);
      expect(dispatcher.canCreateJob, isTrue);
      expect(dispatcher.roleDisplay, 'ผู้จัดสรรงาน');

      final tech = User.fromJson({
        'id': 3,
        'username': 'technician',
        'email': 'technician@serviceflow.com',
        'fullName': 'สมชาย ใจดี',
        'role': 'TECHNICIAN',
        'active': true,
      });

      expect(tech.isAdmin, isFalse);
      expect(tech.isDispatcher, isFalse);
      expect(tech.isTechnician, isTrue);
      expect(tech.canCreateJob, isFalse);
      expect(tech.roleDisplay, 'ช่างเทคนิค');
    });
  });

  group('AuthController & AuthRepository Flow Tests', () {
    final authController = AuthController.instance;

    setUp(() async {
      await authController.logout();
    });

    test('Login with valid ADMIN credentials succeeds and sets state', () async {
      final success = await authController.login('admin', 'Admin@123456');

      expect(success, isTrue);
      expect(authController.isAuthenticated, isTrue);
      expect(authController.currentUser?.role, 'ADMIN');
      expect(authController.canCreateJob, isTrue);
      expect(authController.token, isNotNull);
    });

    test('Login with valid TECHNICIAN credentials succeeds and restricts createJob', () async {
      final success = await authController.login('technician', 'Technician@123');

      expect(success, isTrue);
      expect(authController.isAuthenticated, isTrue);
      expect(authController.currentUser?.role, 'TECHNICIAN');
      expect(authController.canCreateJob, isFalse);
    });

    test('Login with invalid credentials fails and sets error message', () async {
      final success = await authController.login('admin', 'wrong_password');

      expect(success, isFalse);
      expect(authController.isAuthenticated, isFalse);
      expect(authController.errorMessage, isNotNull);
    });

    test('Logout clears authenticated user and token', () async {
      await authController.login('admin', 'Admin@123456');
      expect(authController.isAuthenticated, isTrue);

      await authController.logout();
      expect(authController.isAuthenticated, isFalse);
      expect(authController.currentUser, isNull);
      expect(authController.token, isNull);
    });
  });

  group('LoginScreen UI Widget Tests', () {
    setUp(() async {
      await AuthController.instance.logout();
    });

    testWidgets('LoginScreen renders form fields, buttons, and logos', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('เข้าสู่ระบบ'), findsNWidgets(2)); // Title and button
      expect(find.byType(TextFormField), findsNWidgets(2)); // Username/Email & Password
      expect(find.text('ชื่อผู้ใช้ หรือ อีเมล'), findsOneWidget);
      expect(find.text('รหัสผ่าน'), findsOneWidget);
      expect(find.text('จดจำฉัน'), findsOneWidget);
      expect(find.text('ลืมรหัสผ่าน?'), findsOneWidget);
    });

    testWidgets('Submitting invalid credentials displays error SnackBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.at(0), 'admin');
      await tester.enterText(inputs.at(1), 'wrong_pass');
      await tester.tap(find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('ชื่อผู้ใช้งานหรือรหัสผ่านไม่ถูกต้อง'), findsOneWidget);
    });

    testWidgets('Submitting valid credentials navigates to DashboardScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.at(0), 'admin');
      await tester.enterText(inputs.at(1), 'Admin@123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ'));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });

  group('Role-Based Navigation & UX Permission Tests', () {
    testWidgets('Dashboard as TECHNICIAN hides create job button', (tester) async {
      await AuthController.instance.login('technician', 'Technician@123');

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check header greeting
      expect(find.text('สมชาย ใจดี'), findsOneWidget);
      expect(find.text('ช่างเทคนิค'), findsOneWidget);
      expect(find.text('งานของฉันวันนี้'), findsOneWidget);

      // Verify create job (+) button is hidden in bottom navigation
      final nav = tester.widget<CustomBottomNavigation>(find.byType(CustomBottomNavigation));
      expect(nav.showCreateJobButton, isFalse);
      expect(find.byIcon(Icons.add_rounded), findsNothing);
    });

    testWidgets('Dashboard as ADMIN shows create job button', (tester) async {
      await AuthController.instance.login('admin', 'Admin@123456');

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check header greeting (appears in full name and role badge)
      expect(find.text('ผู้ดูแลระบบ'), findsNWidgets(2));
      expect(find.text('รายการงานวันนี้'), findsOneWidget);

      // Verify create job (+) button is present in bottom navigation
      final nav = tester.widget<CustomBottomNavigation>(find.byType(CustomBottomNavigation));
      expect(nav.showCreateJobButton, isTrue);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('Profile dialog displays user info and logs out cleanly', (tester) async {
      await AuthController.instance.login('admin', 'Admin@123456');

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap profile tab in bottom nav (index 3)
      await tester.tap(find.text('โปรไฟล์'));
      await tester.pumpAndSettle();

      // Check dialog content
      expect(find.text('โปรไฟล์ผู้ใช้งาน'), findsOneWidget);
      expect(find.text('ออกจากระบบ'), findsOneWidget);

      // Tap logout
      await tester.tap(find.text('ออกจากระบบ'));
      await tester.pumpAndSettle();

      // Should be redirected to LoginScreen and user logged out
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(AuthController.instance.isAuthenticated, isFalse);
    });
  });
}
