import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'dashboard_screen.dart';

/// หน้าจอเข้าสู่ระบบ (Login Screen - หน้า 2)
/// รองรับ Form Validation, Loading State, Mock Auth และปุ่มเข้าสู่ระบบด้วย Google
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers สำหรับ Email และ Password พร้อมค่า Mock เริ่มต้นเพื่อความสะดวกในการทดสอบ
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// ตรวจสอบความถูกต้องของชื่อผู้ใช้หรืออีเมล
  String? _validateUsernameOrEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกชื่อผู้ใช้หรืออีเมล';
    }
    if (value.trim().length < 3) {
      return 'ชื่อผู้ใช้หรืออีเมลต้องมีอย่างน้อย 3 ตัวอักษร';
    }
    return null;
  }

  /// ตรวจสอบความถูกต้องของรหัสผ่าน
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกรหัสผ่าน';
    }
    if (value.length < 6) {
      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    }
    return null;
  }

  /// ดำเนินการเข้าสู่ระบบผ่าน Spring Boot Backend ด้วย JWT
  Future<void> _handleLogin() async {
    // ปิดคีย์บอร์ด
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final usernameOrEmail = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await AuthController.instance.login(usernameOrEmail, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // นำทางไปยัง Dashboard Screen และป้องกันการย้อนกลับ
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
    } else {
      final errorMsg = AuthController.instance.errorMessage ??
          'ชื่อผู้ใช้งานหรือรหัสผ่านไม่ถูกต้อง';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// แจ้งเตือนฟังก์ชันที่ยังไม่เปิดใช้งาน
  void _showFeatureNotAvailable(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName: ฟีเจอร์นี้ยังไม่เปิดใช้งาน'),
        backgroundColor: const Color(0xFF475569),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // โลโก้สี่เหลี่ยมมุมโค้งมน สีน้ำเงิน พร้อมรูปประแจสีขาว
                  Center(child: _buildLogo()),

                  const SizedBox(height: 14),

                  // ชื่อแอป ServiceFlow
                  Center(child: _buildAppName()),

                  const SizedBox(height: 18),

                  // หัวข้อ "เข้าสู่ระบบ"
                  const Text(
                    'เข้าสู่ระบบ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ข้อความรอง "เข้าสู่ระบบเพื่อใช้งานแอป"
                  const Text(
                    'เข้าสู่ระบบเพื่อใช้งานแอป',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ช่องกรอก Email
                  _buildEmailField(),

                  const SizedBox(height: 16),

                  // ช่องกรอก Password
                  _buildPasswordField(),

                  const SizedBox(height: 12),

                  // แถว Checkbox "จดจำฉัน" และ "ลืมรหัสผ่าน?"
                  _buildRememberAndForgotRow(),

                  const SizedBox(height: 20),

                  // ปุ่มเข้าสู่ระบบ สีน้ำเงิน เต็มความกว้าง
                  _buildLoginButton(),

                  const SizedBox(height: 24),

                  // เส้นคั่นพร้อมข้อความ "หรือ"
                  _buildDivider(),

                  const SizedBox(height: 20),

                  // ปุ่มเข้าสู่ระบบด้วย Google
                  _buildGoogleLoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ส่วนแสดงโลโก้ตรงกลาง
  Widget _buildLogo() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFF0066E6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066E6).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.build_rounded,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  /// ส่วนแสดงชื่อแอป ServiceFlow
  Widget _buildAppName() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        children: [
          TextSpan(
            text: 'Service',
            style: TextStyle(color: Color(0xFF0B2347)),
          ),
          TextSpan(
            text: 'Flow',
            style: TextStyle(color: Color(0xFF0066E6)),
          ),
        ],
      ),
    );
  }

  /// ช่องกรอก Email พร้อมไอคอนผู้ใช้
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      validator: _validateUsernameOrEmail,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF64748B)),
        hintText: 'ชื่อผู้ใช้ หรือ อีเมล',
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0066E6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }

  /// ช่องกรอก Password พร้อมไอคอนกุญแจ และปุ่มแสดง/ซ่อนรหัสผ่าน
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      validator: _validatePassword,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF64748B)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: const Color(0xFF64748B),
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        hintText: 'รหัสผ่าน',
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0066E6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }

  /// แถว Checkbox "จดจำฉัน" และข้อความ "ลืมรหัสผ่าน?"
  Widget _buildRememberAndForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                activeColor: const Color(0xFF0066E6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                onChanged: (val) {
                  setState(() {
                    _rememberMe = val ?? false;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              },
              child: const Text(
                'จดจำฉัน',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () => _showFeatureNotAvailable('ลืมรหัสผ่าน'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'ลืมรหัสผ่าน?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0066E6),
            ),
          ),
        ),
      ],
    );
  }

  /// ปุ่มเข้าสู่ระบบ สีน้ำเงิน (#0066E6)
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0066E6),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF0066E6).withValues(alpha: 0.6),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'เข้าสู่ระบบ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  /// เส้นคั่นพร้อมข้อความ "หรือ"
  Widget _buildDivider() {
    return Row(
      children: const [
        Expanded(
          child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.0),
          child: Text(
            'หรือ',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
        ),
      ],
    );
  }

  /// ปุ่มเข้าสู่ระบบด้วย Google
  Widget _buildGoogleLoginButton() {
    return OutlinedButton(
      onPressed: () => _showFeatureNotAvailable('Google Login'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1E293B),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGoogleIcon(),
          const SizedBox(width: 10),
          const Text(
            'เข้าสู่ระบบด้วย Google',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  /// ไอคอน Google สี่สีแบบ Minimal โดยไม่ต้องใช้ไฟล์ภาพภายนอก
  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

/// CustomPainter สำหรับวาดไอคอนตัวอักษร 'G' 4 สีของ Google
class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double radius = w * 0.46;
    final double strokeWidth = w * 0.22;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // ส่วนโค้งสีต่างๆ
    // น้ำเงิน: ส่วนขวา
    canvas.drawArc(rect, -0.7, 1.2, false, bluePaint);
    // เขียว: ส่วนล่าง
    canvas.drawArc(rect, 0.5, 1.3, false, greenPaint);
    // เหลือง: ส่วนซ้าย
    canvas.drawArc(rect, 1.8, 1.3, false, yellowPaint);
    // แดง: ส่วนบน
    canvas.drawArc(rect, 3.1, 1.5, false, redPaint);

    // เส้นตรงแนวนอนตรงกลางตัว G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - strokeWidth * 0.2, cy - strokeWidth * 0.5, radius + strokeWidth * 0.2, strokeWidth),
        const Radius.circular(2),
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
