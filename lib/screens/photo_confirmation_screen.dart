import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/network/api_exceptions.dart';
import '../repositories/job_photo_repository.dart';

/// หน้าจอตรวจสอบและยืนยันรูปภาพ (Photo Confirmation - หน้าที่ 9)
/// แสดงภาพตัวอย่าง, ตัวเลือกประเภทภาพ (ก่อนดำเนินการ / หลังดำเนินการ), ช่องกรอกหมายเหตุ,
/// และปุ่มบันทึกรูปภาพเข้าสู่ Job ID
class PhotoConfirmationScreen extends StatefulWidget {
  final String jobId;
  final XFile imageFile;

  const PhotoConfirmationScreen({
    super.key,
    required this.jobId,
    required this.imageFile,
  });

  @override
  State<PhotoConfirmationScreen> createState() => _PhotoConfirmationScreenState();
}

class _PhotoConfirmationScreenState extends State<PhotoConfirmationScreen> {
  String _selectedType = 'ก่อนดำเนินการ'; // ค่าเริ่มต้น: ก่อนดำเนินการ
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// บันทึกรูปภาพเข้าสู่ JobPhotoRepository
  Future<void> _handleSavePhoto() async {
    if (_isSaving) return; // ป้องกัน Double Submit

    // ตรวจสอบความถูกต้องของไฟล์รูปภาพ
    if (!kIsWeb) {
      final file = File(widget.imageFile.path);
      if (!file.existsSync()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ไม่พบไฟล์รูปภาพ กรุณาถ่ายหรือเลือกรูปใหม่อีกครั้ง'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      await JobPhotoRepository.instance.addPhoto(
        jobId: widget.jobId,
        sourceFile: widget.imageFile,
        photoType: _selectedType,
        note: _noteController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('บันทึกรูปภาพสำเร็จ'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // กลับสู่หน้า Job Detail พร้อมผลลัพธ์ว่าบันทึกสำเร็จ
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการบันทึกรูปภาพ: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text(
          'ตัวอย่างรูปภาพ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. กรอบแสดงภาพตัวอย่าง พร้อม badge แสดงจำนวนภาพ "1/1"
                    _buildImagePreview(),

                    const SizedBox(height: 20),

                    // 2. เลือกประเภทภาพ (ก่อนดำเนินการ / หลังดำเนินการ)
                    const Text(
                      'ประเภทภาพ *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPhotoTypeSelector(),

                    const SizedBox(height: 20),

                    // 3. ช่องกรอกหมายเหตุ
                    const Text(
                      'หมายเหตุ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      minLines: 3,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        hintText: 'ระบุรายละเอียดเกี่ยวกับรูปภาพ',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(14),
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
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 4. ปุ่มบันทึกรูปภาพเต็มความกว้าง
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  /// แสดงรูปภาพตัวอย่างพร้อมป้าย "1/1"
  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ภาพถ่าย / รูปภาพที่เลือก
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 200,
              maxHeight: 320,
            ),
            child: kIsWeb
                ? Image.network(
                    widget.imageFile.path,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  )
                : Image.file(
                    File(widget.imageFile.path),
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_rounded, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 8),
                            Text('ไม่สามารถโหลดภาพได้', style: TextStyle(color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),

          // ป้ายบอกจำนวนรูปภาพ "1/1"
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '1/1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ส่วนเลือกประเภทภาพ (ก่อนดำเนินการ / หลังดำเนินการ)
  Widget _buildPhotoTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption(
            title: 'ก่อนดำเนินการ',
            isSelected: _selectedType == 'ก่อนดำเนินการ',
            onTap: () => setState(() => _selectedType = 'ก่อนดำเนินการ'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeOption(
            title: 'หลังดำเนินการ',
            isSelected: _selectedType == 'หลังดำเนินการ',
            onTap: () => setState(() => _selectedType = 'หลังดำเนินการ'),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0066E6) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF0066E6) : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0066E6) : const Color(0xFF94A3B8),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(Icons.check, size: 12, color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? const Color(0xFF0066E6) : const Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// แถบปุ่มบันทึกรูปภาพด้านล่าง
  Widget _buildBottomBar() {
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
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSavePhoto,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0066E6),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'บันทึกรูปภาพ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
