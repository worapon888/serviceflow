import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/job.dart';
import '../models/job_photo.dart';
import '../repositories/job_photo_repository.dart';
import '../repositories/job_repository.dart';
import '../services/image_picker_service.dart';
import '../widgets/authenticated_image.dart';
import '../widgets/photo_source_bottom_sheet.dart';
import 'completed_job_screen.dart';
import 'job_photo_gallery_screen.dart';
import 'photo_confirmation_screen.dart';
import 'update_job_status_screen.dart';

/// หน้าจอรายละเอียดงาน (Job Detail Screen - หน้าที่ 6)
/// รองรับการดูข้อมูลงาน, ข้อมูลลูกค้า, ตัวชี้สถานะ 3 ขั้นตอน (Step Indicator),
/// และการเปลี่ยนสถานะงาน (เริ่มงาน -> เสร็จสิ้นงาน) พร้อมเชื่อมต่อ JobRepository แบบ Real-time
class JobDetailScreen extends StatefulWidget {
  final String jobId;

  JobDetailScreen({
    super.key,
    String? jobId,
    Job? job,
  }) : jobId = jobId ?? job?.id ?? '';

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final JobRepository _repo = JobRepository.instance;
  final JobPhotoRepository _photoRepo = JobPhotoRepository.instance;
  final ImagePickerService _imagePickerService = ImagePickerService();
  bool _isUpdating = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.jobId.isNotEmpty) {
        _repo.getJobByIdRemote(widget.jobId);
        _photoRepo.fetchJobPhotos(widget.jobId);
      }
    });
  }

  /// แสดง Modal Bottom Sheet เลือกแหล่งรูปภาพ (หน้าที่ 7) -> เปิด Camera/Gallery (หน้าที่ 8) -> ส่งไปหน้ายืนยันรูปภาพ (หน้าที่ 9)
  Future<void> _handlePickSitePhoto(String jobId) async {
    final source = await PhotoSourceBottomSheet.show(context);
    if (source == null || !mounted) return;

    setState(() => _isPickingImage = true);

    try {
      final XFile? file = await _imagePickerService.pickImage(source);
      if (file != null && mounted) {
        // เปิดหน้าตรวจสอบและยืนยันรูปภาพ (หน้าที่ 9)
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => PhotoConfirmationScreen(
              jobId: jobId,
              imageFile: file,
            ),
          ),
        );
        if (saved == true && mounted) {
          _photoRepo.fetchJobPhotos(jobId);
          _repo.getJobByIdRemote(jobId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'เกิดข้อผิดพลาดในการเปิด ${source == ImageSource.camera ? "กล้อง" : "แกลเลอรี"}: $e',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  /// นำทางไปยังหน้าคลังรูปภาพหน้างานทั้งหมด (Job Photo Gallery - หน้าที่ 11)
  void _navigateToGallery(String jobId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobPhotoGalleryScreen(jobId: jobId),
      ),
    );
  }

  /// นำทางไปยังหน้าจออัปเดตสถานะงาน (Update Job Status - หน้าที่ 12)
  Future<void> _navigateToUpdateStatus(Job job) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => UpdateJobStatusScreen(jobId: job.id),
      ),
    );

    if (result == true && mounted) {
      final updatedJob = _repo.getJobById(job.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('อัปเดตสถานะงานเป็น "${updatedJob?.status ?? ""}" สำเร็จ'),
              ),
            ],
          ),
          backgroundColor: updatedJob?.statusColor ?? const Color(0xFF0066E6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// แสดง Dialog ยืนยันการเริ่มงาน (รอดำเนินการ -> กำลังดำเนินการ)
  Future<void> _confirmStartJob(Job job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.play_circle_outline_rounded, color: Color(0xFF0066E6)),
            SizedBox(width: 8),
            Text('ยืนยันเริ่มงาน?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'คุณต้องการเริ่มปฏิบัติงาน "${job.title}" (${job.id}) ใช่หรือไม่?\nสถานะจะเปลี่ยนเป็น "กำลังดำเนินการ"',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066E6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('เริ่มงาน'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isUpdating = true);
      final success = await _repo.updateJobStatus(job.id, 'กำลังดำเนินการ');
      if (mounted) {
        setState(() => _isUpdating = false);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เริ่มปฏิบัติงานแล้ว (${job.id})'),
            backgroundColor: const Color(0xFF0284C7),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_repo.errorMessage ?? 'ไม่สามารถเปลี่ยนสถานะได้'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// แสดง Dialog ยืนยันการเสร็จสิ้นงาน (กำลังดำเนินการ -> เสร็จสิ้น)
  Future<void> _confirmCompleteJob(Job job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('ยืนยันเสร็จสิ้นงาน?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'คุณได้ปฏิบัติงาน "${job.title}" (${job.id}) เรียบร้อยสมบูรณ์แล้วใช่หรือไม่?\nสถานะจะเปลี่ยนเป็น "เสร็จสิ้น"',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ยืนยันเสร็จสิ้น'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isUpdating = true);
      final success = await _repo.updateJobStatus(job.id, 'เสร็จสิ้น');
      if (mounted) {
        setState(() => _isUpdating = false);
      }

      if (success && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/completed_job'),
            builder: (context) => CompletedJobScreen(jobId: job.id),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_repo.errorMessage ?? 'ไม่สามารถเปลี่ยนสถานะเป็นเสร็จสิ้นได้'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_repo, _photoRepo]),
      builder: (context, _) {
        final job = _repo.getJobById(widget.jobId);

        // กรณีไม่พบข้อมูล Job ID
        if (job == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text('รายละเอียดงาน', style: TextStyle(color: Color(0xFF0F172A))),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFEF4444)),
                    const SizedBox(height: 16),
                    Text(
                      'ไม่พบข้อมูลงาน (รหัส: ${widget.jobId})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('ย้อนกลับ'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

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
              'รายละเอียดงาน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF0F172A), size: 24),
                tooltip: 'อัปเดตสถานะงาน',
                onPressed: () => _navigateToUpdateStatus(job),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF0F172A)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'update_status') {
                    _navigateToUpdateStatus(job);
                  } else if (val == 'gallery') {
                    _navigateToGallery(job.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'update_status',
                    child: Row(
                      children: [
                        Icon(Icons.sync_alt_rounded, size: 18, color: Color(0xFF0066E6)),
                        SizedBox(width: 10),
                        Text('อัปเดตสถานะงาน', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'gallery',
                    child: Row(
                      children: [
                        Icon(Icons.photo_library_outlined, size: 18, color: Color(0xFF64748B)),
                        SizedBox(width: 10),
                        Text('รูปภาพทั้งหมด', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. การ์ดหัวข้องานและสถานะหลัก
                        _buildJobHeaderCard(job),

                        const SizedBox(height: 14),

                        // 2. ข้อมูลลูกค้าและสถานที่ปฏิบัติงาน (ตรงตามภาพต้นแบบ หน้าที่ 13)
                        _buildCustomerCard(job),

                        const SizedBox(height: 14),

                        // 3. รายละเอียดงาน (ตรงตามภาพต้นแบบ หน้าที่ 13)
                        _buildJobDescriptionCard(job),

                        const SizedBox(height: 14),

                        // 4. รูปหน้างาน (หน้าที่ 13)
                        _buildSitePhotoCard(job),

                        const SizedBox(height: 14),

                        // 5. ตัวชี้สถานะงาน (Step Indicator 3 ขั้นตอน / กล่องแจ้งเตือนเมื่อยกเลิก)
                        _buildStepIndicatorCard(job),

                        const SizedBox(height: 14),

                        // 6. ข้อมูลการนัดหมายและผู้รับผิดชอบงาน
                        _buildAppointmentCard(job),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // 5. แถบปุ่ม Action ด้านล่างตามสถานะงาน
                _buildBottomActionBar(job),
              ],
            ),
          ),
        );
      },
    );
  }

  /// การ์ดหัวข้องาน (Job ID, ชื่อ, ป้ายสถานะ, วันที่-เวลา, ป้ายความสำคัญ)
  Widget _buildJobHeaderCard(Job job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // รหัสงาน
              Text(
                job.id,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                ),
              ),
              // Badge สถานะงาน (แตะเพื่ออัปเดตสถานะงาน)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToUpdateStatus(job),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: job.statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          job.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: job.statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit_outlined, size: 12, color: job.statusColor),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ชื่องาน
          Text(
            job.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),

          // วันที่ เวลานัดหมาย และป้ายความสำคัญ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    '${job.date} ${job.time} น.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              // Badge ระดับความสำคัญ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: job.priorityBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: job.priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.priority,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: job.priorityColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// การ์ดตัวชี้สถานะงาน (Step Indicator 3 ขั้นตอน: รอดำเนินการ -> กำลังดำเนินการ -> เสร็จสิ้น)
  Widget _buildStepIndicatorCard(Job job) {
    int currentStep = 0;
    if (job.status == 'กำลังดำเนินการ') {
      currentStep = 1;
    } else if (job.status == 'เสร็จสิ้น') {
      currentStep = 2;
    }

    if (job.status == 'ยกเลิก') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 22),
                SizedBox(width: 8),
                Text(
                  'งานถูกยกเลิกแล้ว',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.statusNote.isNotEmpty
                  ? 'เหตุผลการยกเลิก: ${job.statusNote}'
                  : 'งานนี้ถูกยกเลิกการดำเนินงานแล้ว',
              style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D), height: 1.4),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ขั้นตอนสถานะงาน',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          // ขั้นตอน 1: รอดำเนินการ
          _buildStepRow(
            stepNumber: 1,
            title: 'รอดำเนินการ',
            subtitle: 'งานได้รับการมอบหมายแล้ว รอเริ่มปฏิบัติงาน',
            isDone: currentStep >= 1,
            isActive: currentStep == 0,
            isLast: false,
            activeColor: const Color(0xFFEF4444),
          ),

          // ขั้นตอน 2: กำลังดำเนินการ
          _buildStepRow(
            stepNumber: 2,
            title: 'กำลังดำเนินการ',
            subtitle: 'ช่างกำลังปฏิบัติงาน ณ สถานที่นัดหมาย',
            isDone: currentStep >= 2,
            isActive: currentStep == 1,
            isLast: false,
            activeColor: const Color(0xFF0284C7),
          ),

          // ขั้นตอน 3: เสร็จสิ้น
          _buildStepRow(
            stepNumber: 3,
            title: 'เสร็จสิ้น',
            subtitle: 'งานบริการสำเร็จเรียบร้อยสมบูรณ์',
            isDone: currentStep == 2,
            isActive: currentStep == 2,
            isLast: true,
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    required bool isLast,
    required Color activeColor,
  }) {
    Color circleColor;
    Widget iconWidget;

    if (isDone) {
      circleColor = const Color(0xFF10B981);
      iconWidget = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isActive) {
      circleColor = activeColor;
      iconWidget = Text(
        '$stepNumber',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      );
    } else {
      circleColor = const Color(0xFFE2E8F0);
      iconWidget = Text(
        '$stepNumber',
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: iconWidget),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
                    color: isActive || isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (!isLast) const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// การ์ดข้อมูลลูกค้า (ตรงตามภาพต้นแบบ หน้าที่ 13: ข้อมูลลูกค้า + ปุ่มโทร และปุ่มพิกัดด้านขวา)
  Widget _buildCustomerCard(Job job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลลูกค้า',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อลูกค้า / องค์กร
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            job.client,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // เบอร์โทรศัพท์
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 10),
                        const Text(
                          '0812345678',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // สถานที่ปฏิบัติงาน
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            job.location,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: Color(0xFF475569),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // ปุ่มการติดต่อและนำทางด่วน 2 ปุ่มแนวตั้งตามภาพต้นแบบ
              Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('โทรออก: 0812345678'),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFFEFF6FF),
                        ),
                        child: const Center(
                          child: Icon(Icons.phone_rounded, color: Color(0xFF0066E6), size: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text('นำทางไปยัง: ${job.location}')),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFFEFF6FF),
                        ),
                        child: const Center(
                          child: Icon(Icons.near_me_outlined, color: Color(0xFF0066E6), size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// การ์ดรายละเอียดงาน (ตรงตามภาพต้นแบบ หน้าที่ 13)
  Widget _buildJobDescriptionCard(Job job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายละเอียดงาน',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            job.description.isNotEmpty ? job.description : 'เครื่องปรับอากาศไม่เย็น',
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  /// การ์ดข้อมูลการนัดหมายและผู้รับผิดชอบงาน
  Widget _buildAppointmentCard(Job job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายละเอียดการปฏิบัติงาน',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          _buildInfoRow('ประเภทงาน:', job.jobType),
          const SizedBox(height: 8),
          _buildInfoRow('ผู้รับผิดชอบ:', job.technician),
          const SizedBox(height: 8),
          _buildInfoRow('วัน-เวลานัดหมาย:', '${job.date} เวลา ${job.time} น.'),
          if (job.statusNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow('หมายเหตุสถานะ:', job.statusNote),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  /// แถบปุ่ม Action ด้านล่างตามสถานะงาน
  Widget _buildBottomActionBar(Job job) {
    Widget actionChild;

    if (job.status == 'รอดำเนินการ') {
      // ปุ่ม "เริ่มงาน"
      actionChild = ElevatedButton.icon(
        onPressed: _isUpdating ? null : () => _confirmStartJob(job),
        icon: const Icon(Icons.play_arrow_rounded, size: 22),
        label: const Text('เริ่มงาน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0066E6),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      );
    } else if (job.status == 'กำลังดำเนินการ') {
      // ปุ่ม "เสร็จสิ้นงาน"
      actionChild = ElevatedButton.icon(
        onPressed: _isUpdating ? null : () => _confirmCompleteJob(job),
        icon: const Icon(Icons.check_circle_rounded, size: 22),
        label: const Text('เสร็จสิ้นงาน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      );
    } else if (job.status == 'ยกเลิก') {
      // สถานะยกเลิก: แสดงข้อความแจ้งเตือนสีแดง
      actionChild = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text(
              'งานนี้ถูกยกเลิกแล้ว',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB91C1C),
              ),
            ),
          ],
        ),
      );
    } else {
      // สถานะเสร็จสิ้น: แสดงข้อความแจ้งเตือนแทนปุ่ม
      actionChild = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 22),
            SizedBox(width: 8),
            Text(
              'งานเสร็จสิ้นแล้ว',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF065F46),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: _isUpdating
          ? const Center(
              child: SizedBox(
                height: 50,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0066E6)),
                  ),
                ),
              ),
            )
          : actionChild,
    );
  }

  /// การ์ดรูปหน้างาน (เชื่อมโยงหน้าที่ 7-10: Photo Capture, Confirmation & Thumbnails)
  Widget _buildSitePhotoCard(Job job) {
    final List<JobPhoto> photos = _photoRepo.getPhotosByJobId(job.id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                photos.isEmpty ? 'รูปหน้างาน' : 'รูปหน้างาน (${photos.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (photos.isNotEmpty)
                InkWell(
                  onTap: () => _navigateToGallery(job.id),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ดูทั้งหมด',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066E6),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Color(0xFF0066E6),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // ถ้ายังไม่มีรูปภาพ: แสดงกรอบเส้นประสีฟ้า + ไอคอนกล้อง + ยังไม่มีรูปภาพ + กดเพื่อเพิ่มรูปหน้างาน
          if (photos.isEmpty)
            CustomPaint(
              painter: const DashedRectPainter(
                color: Color(0xFF93C5FD), // กรอบเส้นประสีฟ้า
                strokeWidth: 1.5,
                gap: 5.0,
                radius: 14.0,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isPickingImage ? null : () => _handlePickSitePhoto(job.id),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    height: 145,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isPickingImage
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0066E6)),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'กำลังเปิดแหล่งรูปภาพ...',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 26,
                                    color: Color(0xFF0066E6),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'ยังไม่มีรูปภาพ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'กดเพื่อเพิ่มรูปหน้างาน',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            )
          else
            // ถ้ามีรูปที่บันทึกแล้ว: แสดงรายการ Thumbnail พร้อมปุ่ม + เพิ่มรูป และปุ่มถ่ายรูปเพิ่มเติม
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 95,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      if (index < photos.length) {
                        final photo = photos[index];
                        return _buildPhotoThumbnail(photo, job.id);
                      } else {
                        // ปุ่ม + เพิ่มรูป ในแถว Thumbnail
                        return _buildAddPhotoThumbnail(job.id);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // ปุ่ม "ถ่ายรูปเพิ่มเติม" ด้านล่างแถว Thumbnail
                OutlinedButton.icon(
                  onPressed: _isPickingImage ? null : () => _handlePickSitePhoto(job.id),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text(
                    'ถ่ายรูปเพิ่มเติม',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0066E6),
                    side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// แสดงรูปภาพ Thumbnail แต่ละรูป พร้อมป้ายประเภท (ก่อน / หลัง) และสามารถกดเพื่อเปิด Gallery ได้
  Widget _buildPhotoThumbnail(JobPhoto photo, String jobId) {
    return InkWell(
      onTap: () => _navigateToGallery(jobId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 95,
        height: 95,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          color: const Color(0xFFF1F5F9),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AuthenticatedImage(
              jobId: jobId,
              photoId: photo.id,
              localPath: photo.imagePath,
              fit: BoxFit.cover,
            ),
            // แถบป้ายประเภทรูปภาพด้านล่าง Thumbnail (ก่อนดำเนินการ / หลังดำเนินการ)
            Positioned(
              left: 4,
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
                decoration: BoxDecoration(
                  color: photo.photoType == 'ก่อนดำเนินการ'
                      ? const Color(0xFFD97706).withValues(alpha: 0.92)
                      : const Color(0xFF059669).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  photo.photoType,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ปุ่ม + เพิ่มรูป ในแถว Thumbnail
  Widget _buildAddPhotoThumbnail(String jobId) {
    return CustomPaint(
      painter: const DashedRectPainter(
        color: Color(0xFF0066E6),
        strokeWidth: 1.5,
        gap: 4.0,
        radius: 12.0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isPickingImage ? null : () => _handlePickSitePhoto(jobId),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 95,
            height: 95,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_rounded, color: Color(0xFF0066E6), size: 28),
                SizedBox(height: 4),
                Text(
                  'เพิ่มรูป',
                  style: TextStyle(
                    color: Color(0xFF0066E6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter สำหรับวาดกรอบเส้นประขอบมน (Dashed Rounded Rectangle)
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  const DashedRectPainter({
    this.color = const Color(0xFF93C5FD),
    this.strokeWidth = 1.5,
    this.gap = 5.0,
    this.radius = 14.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + 6.0 < metric.length) ? 6.0 : metric.length - distance;
        dashPath.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        distance += 6.0 + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.radius != radius;
  }
}

