import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/job_photo.dart';
import '../repositories/job_photo_repository.dart';
import '../services/image_picker_service.dart';
import '../widgets/authenticated_image.dart';
import '../widgets/photo_source_bottom_sheet.dart';
import 'photo_confirmation_screen.dart';

/// หน้าจอคลังรูปภาพหน้างานทั้งหมด (Job Photo Gallery - หน้าที่ 11)
/// แสดงรายการรูปภาพทั้งหมดของ Job ID นั้นๆ เรียงจากใหม่ไปเก่า พร้อมดูรูปขนาดใหญ่ ดูรายละเอียด และลบรูปภาพ
class JobPhotoGalleryScreen extends StatefulWidget {
  final String jobId;

  const JobPhotoGalleryScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<JobPhotoGalleryScreen> createState() => _JobPhotoGalleryScreenState();
}

class _JobPhotoGalleryScreenState extends State<JobPhotoGalleryScreen> {
  final JobPhotoRepository _photoRepo = JobPhotoRepository.instance;
  final ImagePickerService _imagePickerService = ImagePickerService();
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.jobId.isNotEmpty) {
        _photoRepo.fetchJobPhotos(widget.jobId);
      }
    });
  }

  /// ฟังก์ชันแปลง DateTime เป็นรูปแบบภาษาไทยตามภาพต้นแบบ เช่น "12 ม.ค. 2024 09:15"
  String _formatThaiDateTime(DateTime dt) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    final year = dt.year;
    final month = months[dt.month - 1];
    final day = dt.day;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year $hour:$minute';
  }

  /// แสดงตัวเลือกถ่ายรูปหรือเลือกจากคลังภาพ -> เปิดกล้อง/แกลเลอรี -> หน้าจอยืนยันรูปภาพ (หน้าที่ 9)
  Future<void> _handleAddNewPhoto() async {
    if (_isPickingImage) return;

    final source = await PhotoSourceBottomSheet.show(context);
    if (source == null || !mounted) return;

    setState(() => _isPickingImage = true);

    try {
      final XFile? file = await _imagePickerService.pickImage(source);
      if (file != null && mounted) {
        // เปิดหน้าตรวจสอบและยืนยันรูปภาพ (หน้าที่ 9)
        final bool? saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => PhotoConfirmationScreen(
              jobId: widget.jobId,
              imageFile: file,
            ),
          ),
        );

        if (saved == true && mounted) {
          // แจ้งเตือนเมื่อเพิ่มรูปสำเร็จ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('เพิ่มรูปภาพลงในแกลเลอรีสำเร็จ'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
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

  /// เปิดดูภาพขนาดใหญ่แบบ Fullscreen พร้อมระบบ Zoom / Pan
  void _openFullscreen(JobPhoto photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenPhotoViewer(photo: photo),
      ),
    );
  }

  /// แสดง Dialog รายละเอียดรูปภาพ
  void _showPhotoDetails(JobPhoto photo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'รายละเอียดรูปภาพ',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              _buildDetailRow('หมายเลขงาน', widget.jobId),
              const SizedBox(height: 10),
              _buildDetailRow('ประเภทภาพ', photo.photoType),
              const SizedBox(height: 10),
              _buildDetailRow('วันที่บันทึก', _formatThaiDateTime(photo.createdAt)),
              if (photo.note.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildDetailRow('หมายเหตุ', photo.note),
              ],
              const SizedBox(height: 10),
              _buildDetailRow('ที่อยู่ไฟล์', photo.imagePath, isPath: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openFullscreen(photo);
                  },
                  icon: const Icon(Icons.fullscreen_rounded, size: 20),
                  label: const Text('ดูรูปภาพขนาดเต็ม', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066E6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPath = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
              fontFamily: isPath ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }

  /// แสดง Dialog ยืนยันการลบรูปภาพ
  Future<void> _confirmDeletePhoto(JobPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('ยืนยันการลบรูปภาพ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'คุณต้องการลบรูปภาพ "${photo.photoType}" ใช่หรือไม่?\nการกระทำนี้จะลบไฟล์ออกจากเครื่องและไม่สามารถย้อนกลับได้',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ลบรูปภาพ'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _photoRepo.deletePhoto(
        jobId: widget.jobId,
        photoId: photo.id,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('ลบรูปภาพสำเร็จ'),
                ],
              ),
              backgroundColor: const Color(0xFF334155),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ไม่สามารถลบรูปภาพได้เนื่องจากไม่พบข้อมูล'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _photoRepo,
      builder: (context, _) {
        // ดึงรูปภาพของ Job ID ปัจจุบันเท่านั้น เรียงจากใหม่ไปเก่า (Newest First)
        final photos = _photoRepo.getPhotosByJobId(widget.jobId, newestFirst: true);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'รูปหน้างาน (${photos.length})',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => _photoRepo.fetchJobPhotos(widget.jobId),
            color: const Color(0xFF0066E6),
            child: photos.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: _buildEmptyState(),
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: photos.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return _buildPhotoCard(photo);
                    },
                  ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isPickingImage ? null : _handleAddNewPhoto,
                  icon: _isPickingImage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 22),
                  label: Text(
                    _isPickingImage ? 'กำลังโหลด...' : '+ เพิ่มรูป',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066E6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// แสดง Empty State เมื่อไม่มีรูปภาพใน Job
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 40,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'ยังไม่มีรูปภาพ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'กดปุ่ม "+ เพิ่มรูป" ด้านล่าง เพื่อถ่ายภาพหรือเลือกภาพจากคลังเพื่อบันทึกประวัติการทำงาน',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  /// แสดงการ์ดรูปภาพแต่ละรายการตามสไตล์ภาพต้นแบบ หน้าที่ 11
  Widget _buildPhotoCard(JobPhoto photo) {
    final bool isBefore = photo.photoType == 'ก่อนดำเนินการ';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // รูปภาพขนาดใหญ่ มุมโค้งมน พร้อมเปิดดูขนาดเต็มเมื่อกด
          GestureDetector(
            onTap: () => _openFullscreen(photo),
            child: Stack(
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  color: const Color(0xFFF1F5F9),
                  child: Hero(
                    tag: 'photo_hero_${photo.id}',
                    child: AuthenticatedImage(
                      jobId: widget.jobId,
                      photoId: photo.id,
                      localPath: photo.imagePath,
                      fit: BoxFit.cover,
                      errorWidget: _buildImageError(),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // รายละเอียดใต้รูปภาพ
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ไอคอนแสดงประเภทภาพตามภาพต้นแบบ
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isBefore ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isBefore ? const Color(0xFFFFEDD5) : const Color(0xFFDCFCE7),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isBefore ? Icons.camera_alt_outlined : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: isBefore ? const Color(0xFFEA580C) : const Color(0xFF16A34A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ประเภทภาพ วันเวลา และหมายเหตุ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.photoType,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isBefore ? const Color(0xFFC2410C) : const Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatThaiDateTime(photo.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      if (photo.note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          photo.note,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // เมนูสามจุด: ดูรายละเอียดรูปภาพ, ลบรูปภาพ
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF64748B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  onSelected: (value) {
                    if (value == 'view') {
                      _showPhotoDetails(photo);
                    } else if (value == 'delete') {
                      _confirmDeletePhoto(photo);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF0066E6)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ดูรายละเอียดรูปภาพ',
                              style: TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ลบรูปภาพ',
                              style: TextStyle(fontSize: 14, color: Color(0xFFEF4444)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageError() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, size: 36, color: Color(0xFF94A3B8)),
          SizedBox(height: 6),
          Text(
            'ไม่สามารถแสดงรูปภาพได้',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

/// หน้าจอแสดงรูปภาพขนาดใหญ่แบบ Fullscreen พร้อมความสามารถ Zoom / Pan
class FullscreenPhotoViewer extends StatelessWidget {
  final JobPhoto photo;

  const FullscreenPhotoViewer({
    super.key,
    required this.photo,
  });

  String _formatThaiDateTime(DateTime dt) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    final year = dt.year;
    final month = months[dt.month - 1];
    final day = dt.day;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year $hour:$minute น.';
  }

  @override
  Widget build(BuildContext context) {
    final bool isBefore = photo.photoType == 'ก่อนดำเนินการ';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          photo.photoType,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isBefore ? const Color(0xFFFDBA74) : const Color(0xFF86EFAC),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Hero(
                tag: 'photo_hero_${photo.id}',
                child: AuthenticatedImage(
                  jobId: photo.jobId,
                  photoId: photo.id,
                  localPath: photo.imagePath,
                  fit: BoxFit.contain,
                  errorWidget: const Center(
                    child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),

          // แถบข้อมูลด้านล่าง (วันที่ และ หมายเหตุ)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatThaiDateTime(photo.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    if (photo.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        photo.note,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
