import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

/// หน้าจอ Splash Screen ของแอปพลิเคชัน ServiceFlow
/// ตามดีไซน์: โลโก้พร้อมไอคอนประแจ, ชื่อแอปแบบทูโทน, เงาตึก Minimal ด้วย CustomPainter
/// และแถบแสดงความคืบหน้า (Progress Bar) ที่เคลื่อนไหวอย่างราบรื่น
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // 1. Controller สำหรับ Fade In และ Scale Animation ของ Logo และหัวข้อ
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutBack,
      ),
    );

    // 2. Controller สำหรับจำลอง Loading Progress Bar ด้านล่าง (0% -> 100%)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    // เริ่มเล่น Animation
    _fadeController.forward();
    _progressController.forward();

    // กู้คืนเซสชันขณะแสดง Splash Screen
    final restoreFuture = AuthController.instance.restoreSession();

    // 3. แสดงหน้าจอประมาณ 2 วินาที แล้วสลับไปยังหน้า Dashboard หรือ Login ตามสถานะเซสชัน
    _navigationTimer = Timer(const Duration(milliseconds: 2100), () async {
      await restoreFuture;
      if (mounted) {
        final destination = AuthController.instance.isAuthenticated
            ? const DashboardScreen()
            : const LoginScreen();

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => destination,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ส่วนล่าง: ภาพเงาอาคาร Minimal สร้างด้วย CustomPainter
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: screenHeight * 0.28,
            child: const CustomPaint(
              painter: BuildingSkylinePainter(),
            ),
          ),

          // ส่วนกลาง: โลโก้ ชื่อแอป และคำบรรยาย พร้อม Fade In Animation
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // โลโก้สี่เหลี่ยมมุมมนสีน้ำเงิน (#0066E6) ภายในมีรูปประแจสีขาว
                          _buildAppLogo(),

                          const SizedBox(height: 22),

                          // ชื่อแอป ServiceFlow
                          _buildAppName(),

                          const SizedBox(height: 10),

                          // ข้อความรอง: Field Service Management
                          const Text(
                            'Field Service Management',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.3,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // ข้อความภาษาไทย: จัดการงานบริการได้ทุกที่
                          const Text(
                            'จัดการงานบริการได้ทุกที่',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ด้านล่างสุด: แถบ Loading Progress
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding + 28,
            child: Center(
              child: _buildProgressBar(),
            ),
          ),
        ],
      ),
    );
  }

  /// โลโก้สี่เหลี่ยมมุมโค้งมน สีน้ำเงินสด (#0066E6) พร้อมประแจสีขาวเอียง 45 องศา
  Widget _buildAppLogo() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF0066E6),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066E6).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Transform.rotate(
          angle: -math.pi / 4, // เอียงประแจตาม Visual Reference
          child: const Icon(
            Icons.build_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// ชื่อแอป ServiceFlow (Service: สีน้ำเงินเข้ม, Flow: สีน้ำเงินสด)
  Widget _buildAppName() {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        children: [
          TextSpan(
            text: 'Service',
            style: TextStyle(
              color: Color(0xFF0B2347), // สีน้ำเงินเข้ม
            ),
          ),
          TextSpan(
            text: 'Flow',
            style: TextStyle(
              color: Color(0xFF0066E6), // สีน้ำเงินสด
            ),
          ),
        ],
      ),
    );
  }

  /// แถบ Loading Progress สีน้ำเงินและสีเทาอ่อน
  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          width: 140,
          height: 4.5,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0), // แถบสีเทาอ่อน
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: _progressAnimation.value.clamp(0.05, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0066E6), // แถบสีน้ำเงินคืบหน้า
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// CustomPainter สำหรับวาดภาพเงาตึกอาคารสีฟ้าอ่อนสไตล์ Minimal
class BuildingSkylinePainter extends CustomPainter {
  const BuildingSkylinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // เลเยอร์ตึกด้านหลัง (สีฟ้าอ่อนมาก โปร่งแสง)
    final backBuildingPaint = Paint()
      ..color = const Color(0xFFF1F6FD)
      ..style = PaintingStyle.fill;

    // เลเยอร์ตึกแถวหน้า (สีฟ้าอ่อนพาสเทล)
    final frontBuildingPaint = Paint()
      ..color = const Color(0xFFE5EEFA)
      ..style = PaintingStyle.fill;

    // จุดหน้าต่างตึก (สีขาวจางๆ)
    final windowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // 1. ตึกแถวด้านหลัง
    final backBuildings = [
      Rect.fromLTWH(width * 0.05, height * 0.25, width * 0.16, height * 0.75),
      Rect.fromLTWH(width * 0.24, height * 0.15, width * 0.14, height * 0.85),
      Rect.fromLTWH(width * 0.40, height * 0.32, width * 0.18, height * 0.68),
      Rect.fromLTWH(width * 0.60, height * 0.10, width * 0.15, height * 0.90),
      Rect.fromLTWH(width * 0.78, height * 0.22, width * 0.17, height * 0.78),
    ];

    for (final rect in backBuildings) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        backBuildingPaint,
      );
    }

    // 2. ตึกแถวด้านหน้า
    final frontBuildings = [
      Rect.fromLTWH(width * 0.00, height * 0.45, width * 0.14, height * 0.55),
      Rect.fromLTWH(width * 0.12, height * 0.35, width * 0.15, height * 0.65),
      Rect.fromLTWH(width * 0.30, height * 0.22, width * 0.16, height * 0.78),
      Rect.fromLTWH(width * 0.48, height * 0.38, width * 0.14, height * 0.62),
      Rect.fromLTWH(width * 0.64, height * 0.28, width * 0.17, height * 0.72),
      Rect.fromLTWH(width * 0.83, height * 0.40, width * 0.17, height * 0.60),
    ];

    for (final rect in frontBuildings) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        frontBuildingPaint,
      );

      // วาดตารางหน้าต่างเล็กๆ บนตึก
      _drawWindows(canvas, rect, windowPaint);
    }
  }

  void _drawWindows(Canvas canvas, Rect buildingRect, Paint paint) {
    const double winW = 3.5;
    const double winH = 4.5;
    const double gapX = 5.0;
    const double gapY = 7.0;

    final startX = buildingRect.left + 7;
    final endX = buildingRect.right - 7;
    final startY = buildingRect.top + 10;
    final endY = buildingRect.bottom - 15;

    for (double y = startY; y < endY; y += winH + gapY) {
      for (double x = startX; x < endX; x += winW + gapX) {
        canvas.drawRect(Rect.fromLTWH(x, y, winW, winH), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
