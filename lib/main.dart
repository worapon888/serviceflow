import 'package:flutter/material.dart';
import 'controllers/auth_controller.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ServiceFlowApp());
}

class ServiceFlowApp extends StatefulWidget {
  const ServiceFlowApp({super.key});

  @override
  State<ServiceFlowApp> createState() => _ServiceFlowAppState();
}

class _ServiceFlowAppState extends State<ServiceFlowApp> {
  final AuthController _authController = AuthController.instance;

  @override
  void initState() {
    super.initState();
    _authController.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (_authController.sessionExpired) {
      _authController.clearSessionExpiredNotification();
      rootNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'ServiceFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066E6),
          primary: const Color(0xFF0066E6),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// Alias เพื่อความเข้ากันได้กับเทสต์เดิม
typedef MyApp = ServiceFlowApp;
