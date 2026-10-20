import 'package:flutter/material.dart';
import '../models/job.dart';
import '../repositories/job_repository.dart';
import 'job_detail_screen.dart';
import 'job_list_screen.dart';

/// หน้าจอ Completed Job (อัปเดตสถานะสำเร็จ - หน้าที่ 14)
/// แสดงสถานะสำเร็จหลังเปลี่ยนสถานะงานเป็น "เสร็จสิ้น" พร้อม Animation นุ่มนวล
/// และมีปุ่มนำทาง "ดูรายละเอียด" และ "กลับหน้ารายการงาน"
class CompletedJobScreen extends StatefulWidget {
  final String jobId;

  const CompletedJobScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<CompletedJobScreen> createState() => _CompletedJobScreenState();
}

class _CompletedJobScreenState extends State<CompletedJobScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _contentFadeAnimation;
  late final Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );

    // Animation สำหรับวงกลมเครื่องหมายถูก (Scale + Fade In อย่างนุ่มนวล)
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    // Animation สำหรับข้อความรายละเอียด (Fade In + Slide Up เล็กน้อย)
    _contentFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// เปิด Job Detail ของงานที่เพิ่งปิด (ไม่สร้าง Job Detail ซ้ำ)
  void _handleViewDetails(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/job_detail'),
          builder: (context) => JobDetailScreen(jobId: widget.jobId),
        ),
      );
    }
  }

  /// กลับหน้ารายการงาน (Job List) พร้อมป้องกัน Navigation Stack ซ้อน
  void _handleReturnToJobList(BuildContext context) {
    bool hasJobListInStack = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == '/job_list') {
        hasJobListInStack = true;
        return true;
      }
      return route.isFirst;
    });

    if (!hasJobListInStack) {
      Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/job_list'),
          builder: (context) => const JobListScreen(),
        ),
      );
    }
  }

  String _formatJobId(Job? job) {
    final rawId = job?.id ?? widget.jobId;
    if (rawId.startsWith('#')) {
      return 'งาน $rawId';
    }
    return 'งาน #$rawId';
  }

  @override
  Widget build(BuildContext context) {
    final job = JobRepository.instance.getJobById(widget.jobId);
    final formattedJobTitle = _formatJobId(job);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // การกด Back ของ Android ให้กลับไปที่หน้ารายการงานอย่างปลอดภัย
        _handleReturnToJobList(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 3),

                // 1. ส่วนเนื้อหาตรงกลางพร้อม Animation (วงกลมเขียว + เครื่องหมายถูก + ข้อความ)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // วงกลมสีเขียว + เครื่องหมายถูกสีขาว
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            key: const ValueKey('completed_success_icon'),
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF10B981),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.28),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_rounded,
                                size: 58,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ข้อความแจ้งสถานะสำเร็จ
                      FadeTransition(
                        opacity: _contentFadeAnimation,
                        child: SlideTransition(
                          position: _contentSlideAnimation,
                          child: Column(
                            children: [
                              const Text(
                                'อัปเดตสถานะสำเร็จ',
                                key: ValueKey('completed_status_title'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F2B48),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formattedJobTitle,
                                key: const ValueKey('completed_job_id_text'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'ดำเนินงานเสร็จสิ้นแล้ว',
                                key: ValueKey('completed_job_subtitle'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 4),

                // 2. ปุ่ม Action ด้านล่าง (ดูรายละเอียด & กลับหน้ารายการงาน)
                Column(
                  children: [
                    // ปุ่มหลักสีน้ำเงิน: ดูรายละเอียด
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        key: const ValueKey('completed_view_details_btn'),
                        onPressed: () => _handleViewDetails(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066E6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ดูรายละเอียด',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ปุ่มรองแบบ Outline: กลับหน้ารายการงาน
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        key: const ValueKey('completed_back_to_job_list_btn'),
                        onPressed: () => _handleReturnToJobList(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E293B),
                          side: const BorderSide(
                            color: Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'กลับหน้ารายการงาน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
