import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/job.dart';
import '../repositories/job_repository.dart';
import '../widgets/job_card.dart';
import '../widgets/custom_bottom_nav.dart';
import 'create_job_screen.dart';
import 'job_detail_screen.dart';
import 'login_screen.dart';

/// หน้าจอรายการงาน (Job List Screen - หน้าที่ 4)
/// รองรับการค้นหาแบบ Real-time, ตัวกรองสถานะแบบ Horizontal Chips, และเชื่อมต่อ JobRepository
class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final JobRepository _jobRepo = JobRepository.instance;

  // สถานะตัวกรอง: 'ทั้งหมด', 'รอดำเนินการ', 'กำลังดำเนินการ', 'เสร็จสิ้น'
  String _selectedStatus = 'ทั้งหมด';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jobRepo.fetchJobs();
      _jobRepo.fetchStatistics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// กรองรายการงานตาม Search Query และ Status Filter
  List<Job> get _filteredJobs {
    return _jobRepo.jobs.where((job) {
      // 1. ตรวจสอบสถานะงาน
      final matchesStatus =
          _selectedStatus == 'ทั้งหมด' || job.status == _selectedStatus;

      // 2. ตรวจสอบคำค้นหา (รหัสงาน, ชื่องาน, ลูกค้า, สถานที่)
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          job.id.toLowerCase().contains(query) ||
          job.title.toLowerCase().contains(query) ||
          job.client.toLowerCase().contains(query) ||
          job.location.toLowerCase().contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  void _handleNavigation(int index) {
    if (index == 0) {
      // กลับหน้าหลัก (Dashboard)
      Navigator.of(context).pop();
    } else if (index == 1) {
      // อยู่หน้างานแล้ว
    } else if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ไม่มีการแจ้งเตือนใหม่ในขณะนี้'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (index == 3) {
      _showProfileDialog();
    }
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

  void _openCreateJob() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateJobScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _jobRepo,
      builder: (context, _) {
        // คำนวณจำนวนจริงจาก JobRepository
        final totalCount = _jobRepo.totalCount;
        final pendingCount = _jobRepo.pendingCount;
        final inProgressCount = _jobRepo.inProgressCount;
        final completedCount = _jobRepo.completedCount;
        final cancelledCount = _jobRepo.cancelledCount;

        final displayJobs = _filteredJobs;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Color(0xFF0F172A),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'รายการงาน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Color(0xFF0F172A)),
                onPressed: () {
                  _searchFocusNode.requestFocus();
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // ส่วนค้นหาและตัวกรองสถานะด้านบน
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Column(
                    children: [
                      // 1. Search Bar
                      _buildSearchBar(),

                      const SizedBox(height: 12),

                      // 2. Status Filter Chips (Horizontal)
                      _buildStatusFilterRow(
                        totalCount: totalCount,
                        pendingCount: pendingCount,
                        inProgressCount: inProgressCount,
                        completedCount: completedCount,
                        cancelledCount: cancelledCount,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 3. รายการ Job Cards หรือ Empty State
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _jobRepo.fetchJobs();
                      await _jobRepo.fetchStatistics();
                    },
                    color: const Color(0xFF0066E6),
                    child: displayJobs.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: _buildEmptyState(),
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            itemCount: displayJobs.length,
                            itemBuilder: (context, index) {
                              final job = displayJobs[index];
                              return JobCard(
                                job: job,
                                showPriority: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      settings: const RouteSettings(name: '/job_detail'),
                                      builder: (context) => JobDetailScreen(job: job),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),

          // แถบเมนูด้านล่าง (Shared CustomBottomNavigation - ซ่อนปุ่มสร้างงานสำหรับ TECHNICIAN)
          bottomNavigationBar: ListenableBuilder(
            listenable: AuthController.instance,
            builder: (context, _) => CustomBottomNavigation(
              currentIndex: 1, // แท็บ "งาน" เป็น Active
              onItemSelected: _handleNavigation,
              onCreateJobPressed: _openCreateJob,
              showCreateJobButton: AuthController.instance.canCreateJob,
            ),
          ),
        );
      },
    );
  }

  /// ช่องค้นหาพร้อมไอคอนแว่นขยายและปุ่ม Clear
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'ค้นหางาน ลูกค้า สถานที่...',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Color(0xFF64748B),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        ),
      ),
    );
  }

  /// แถวตัวกรองสถานะแบบ Horizontal Chips
  Widget _buildStatusFilterRow({
    required int totalCount,
    required int pendingCount,
    required int inProgressCount,
    required int completedCount,
    required int cancelledCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            label: 'ทั้งหมด',
            count: totalCount,
            isSelected: _selectedStatus == 'ทั้งหมด',
            onTap: () => setState(() => _selectedStatus = 'ทั้งหมด'),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'รอดำเนินการ',
            count: pendingCount,
            isSelected: _selectedStatus == 'รอดำเนินการ',
            onTap: () => setState(() => _selectedStatus = 'รอดำเนินการ'),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'กำลังดำเนินการ',
            count: inProgressCount,
            isSelected: _selectedStatus == 'กำลังดำเนินการ',
            onTap: () => setState(() => _selectedStatus = 'กำลังดำเนินการ'),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'เสร็จสิ้น',
            count: completedCount,
            isSelected: _selectedStatus == 'เสร็จสิ้น',
            onTap: () => setState(() => _selectedStatus = 'เสร็จสิ้น'),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'ยกเลิก',
            count: cancelledCount,
            isSelected: _selectedStatus == 'ยกเลิก',
            onTap: () => setState(() => _selectedStatus = 'ยกเลิก'),
          ),
        ],
      ),
    );
  }

  /// วิดเจ็ต Chip แต่ละตัว
  Widget _buildChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0066E6) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  /// แสดงผลเมื่อไม่พบรายการที่ตรงกับเงื่อนไข
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ไม่พบรายการงาน',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'ลองค้นหาด้วยคำค้นอื่น หรือเปลี่ยนตัวกรองสถานะงาน',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedStatus != 'ทั้งหมด') ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedStatus = 'ทั้งหมด';
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('ล้างตัวกรองทั้งหมด'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0066E6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
