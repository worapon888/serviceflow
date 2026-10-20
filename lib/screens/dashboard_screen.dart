import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../repositories/job_repository.dart';
import '../widgets/stat_card.dart';
import '../widgets/job_card.dart';
import '../widgets/custom_bottom_nav.dart';
import 'job_list_screen.dart';
import 'create_job_screen.dart';
import 'job_detail_screen.dart';
import 'login_screen.dart';

/// หน้าจอ Dashboard Screen (หน้าที่ 3) สำหรับแอปพลิเคชัน ServiceFlow
/// เชื่อมต่อกับ JobRepository Single Source of Truth เพื่ออัปเดตสถิติและรายการงานแบบ Real-time
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;
  final JobRepository _jobRepo = JobRepository.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _jobRepo.fetchJobs(),
      _jobRepo.fetchStatistics(),
    ]);
  }

  void _handleNavigation(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    if (index == 1) {
      // ไปยังหน้ารายการงาน (Job List)
      Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/job_list'),
          builder: (context) => const JobListScreen(),
        ),
      ).then((_) {
        if (mounted) {
          setState(() => _currentNavIndex = 0);
        }
      });
    } else if (index == 2) {
      // แจ้งเตือน
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ไม่มีการแจ้งเตือนใหม่ในขณะนี้'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (index == 3) {
      // เมนูโปรไฟล์ พร้อมปุ่มออกจากระบบ
      _showProfileDialog();
    }
  }

  void _openCreateJob() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateJobScreen()),
    );
  }

  void _showProfileDialog() {
    final user = AuthController.instance.currentUser;
    final fullName = (user?.fullName.isNotEmpty ?? false) ? user!.fullName : 'ผู้ดูแลระบบ';
    final roleDisplay = user?.roleDisplay ?? 'ผู้ใช้งาน';
    final email = user?.email ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('โปรไฟล์ผู้ใช้งาน', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFF0066E6),
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0066E6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                roleDisplay,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0066E6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(email, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ปิด'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await AuthController.instance.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListenableBuilder(
        listenable: _jobRepo,
        builder: (context, _) {
          final jobs = _jobRepo.jobs;
          final totalCount = _jobRepo.totalCount;
          final pendingCount = _jobRepo.pendingCount;
          final inProgressCount = _jobRepo.inProgressCount;
          final completedCount = _jobRepo.completedCount;

          return Stack(
            children: [
              // พื้นหลัง Header Gradient สีน้ำเงินด้านบน
              Container(
                height: 190,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0066E6), Color(0xFF004CB8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),

              SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF0066E6),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // 1. Header: ข้อมูลผู้ใช้ และปุ่มกระดิ่งแจ้งเตือน
                        _buildHeader(),

                        const SizedBox(height: 18),

                        // 2. Statistics Cards: แถวการ์ดสถิติ 4 ใบแนวนอนตามแบบ
                        _buildStatCardsRow(
                          total: totalCount,
                          pending: pendingCount,
                          inProgress: inProgressCount,
                          completed: completedCount,
                        ),

                        const SizedBox(height: 24),

                        // 3. งานของฉันวันนี้ Header
                        _buildSectionHeader(),

                        const SizedBox(height: 12),

                        // 4. รายการ Job Cards 3 รายการตามที่กำหนดใน Dashboard
                        ...jobs.take(3).map((job) => JobCard(
                              job: job,
                              showPriority: false,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    settings: const RouteSettings(name: '/job_detail'),
                                    builder: (context) => JobDetailScreen(job: job),
                                  ),
                                );
                              },
                            )),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // แถบเมนู Bottom Navigation (ซ่อนปุ่มสร้างงานสำหรับ TECHNICIAN)
      bottomNavigationBar: ListenableBuilder(
        listenable: AuthController.instance,
        builder: (context, _) => CustomBottomNavigation(
          currentIndex: _currentNavIndex,
          onItemSelected: _handleNavigation,
          onCreateJobPressed: _openCreateJob,
          showCreateJobButton: AuthController.instance.canCreateJob,
        ),
      ),
    );
  }

  /// ส่วนหัว Header แสดงรูปโปรไฟล์, สวัสดีครับ, ชื่อผู้ใช้, บทบาท และกระดิ่ง
  Widget _buildHeader() {
    final user = AuthController.instance.currentUser;
    final fullName = (user?.fullName.isNotEmpty ?? false) ? user!.fullName : 'สมชาย ใจดี';
    final roleDisplay = user?.roleDisplay ?? 'ช่างเทคนิค';

    return Row(
      children: [
        // รูปโปรไฟล์วงกลมพร้อมขอบสีขาว
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFDCEBFE),
            child: Icon(
              Icons.person_rounded,
              color: Color(0xFF0066E6),
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // ข้อความทักทายและข้อมูลผู้ใช้งาน
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'สวัสดีครับ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text('👋', style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                roleDisplay,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFBAE6FD),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // ปุ่มกระดิ่งแจ้งเตือนพร้อมจุดสีแดง
        GestureDetector(
          onTap: () => _handleNavigation(2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              Positioned(
                top: 7,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// การ์ดสถิติ 4 ใบเรียงแนวนอน (ทั้งหมด, รอดำเนินการ, กำลังดำเนินการ, เสร็จสิ้น) คำนวณจาก Repository
  Widget _buildStatCardsRow({
    required int total,
    required int pending,
    required int inProgress,
    required int completed,
  }) {
    return Row(
      children: [
        // 1. ทั้งหมด — สีน้ำเงิน
        StatCard(
          label: 'ทั้งหมด',
          count: total.toString(),
          trend: '+12%',
          isTrendPositive: true,
          icon: Icons.list_alt_rounded,
          themeColor: const Color(0xFF0066E6),
        ),
        const SizedBox(width: 8),

        // 2. รอดำเนินการ — สีแดง
        StatCard(
          label: 'รอดำเนินการ',
          count: pending.toString(),
          trend: '+2%',
          isTrendPositive: false,
          icon: Icons.hourglass_top_rounded,
          themeColor: const Color(0xFFEF4444),
        ),
        const SizedBox(width: 8),

        // 3. กำลังดำเนินการ — สีฟ้า
        StatCard(
          label: 'กำลังดำเนินการ',
          count: inProgress.toString(),
          trend: '+29%',
          isTrendPositive: true,
          icon: Icons.sync_rounded,
          themeColor: const Color(0xFF0284C7),
        ),
        const SizedBox(width: 8),

        // 4. เสร็จสิ้น — สีเขียว
        StatCard(
          label: 'เสร็จสิ้น',
          count: completed.toString(),
          trend: '+50%',
          isTrendPositive: true,
          icon: Icons.check_circle_outline_rounded,
          themeColor: const Color(0xFF10B981),
        ),
      ],
    );
  }

  /// หัวข้อส่วนงานของฉันวันนี้ / รายการงานวันนี้ พร้อมปุ่ม "ดูทั้งหมด >"
  Widget _buildSectionHeader() {
    final isTech = AuthController.instance.isTechnician;
    final title = isTech ? 'งานของฉันวันนี้' : 'รายการงานวันนี้';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                settings: const RouteSettings(name: '/job_list'),
                builder: (context) => const JobListScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Row(
              children: const [
                Text(
                  'ดูทั้งหมด',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0066E6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: Color(0xFF0066E6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
