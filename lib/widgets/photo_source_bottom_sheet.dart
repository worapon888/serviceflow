import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Modal Bottom Sheet สำหรับเลือกแหล่งที่มาของรูปภาพ (หน้าที่ 7)
/// อ้างอิงตามดีไซน์ ServiceFlow (กล้องสีน้ำเงิน / แกลเลอรีสีเขียว / ปุ่มยกเลิก)
class PhotoSourceBottomSheet extends StatelessWidget {
  const PhotoSourceBottomSheet({super.key});

  /// เมธอดสะดวกสำหรับเรียกแสดง Bottom Sheet และรับค่า ImageSource ที่ผู้ใช้เลือก
  static Future<ImageSource?> show(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PhotoSourceBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // แถบด้านบน: หัวข้อ "เพิ่มรูปหน้างาน" และปุ่ม 'X' ปิด
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'เพิ่มรูปหน้างาน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  splashRadius: 20,
                  tooltip: 'ปิด',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ตัวเลือก 1: ถ่ายรูป (กล้องสีน้ำเงิน)
            _buildSourceOption(
              context: context,
              source: ImageSource.camera,
              icon: Icons.camera_alt_rounded,
              iconBgColor: const Color(0xFF0066E6),
              title: 'ถ่ายรูป',
              subtitle: 'เปิดกล้องเพื่อถ่ายรูปหน้างาน',
            ),
            const SizedBox(height: 12),

            // ตัวเลือก 2: เลือกรูปจากแกลเลอรี (ไอคอนสีเขียว)
            _buildSourceOption(
              context: context,
              source: ImageSource.gallery,
              icon: Icons.photo_library_rounded,
              iconBgColor: const Color(0xFF10B981),
              title: 'เลือกจากแกลเลอรี',
              subtitle: 'เลือกรูปจากไฟล์ในเครื่อง',
            ),
            const SizedBox(height: 20),

            // ปุ่มยกเลิก
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(null),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF475569),
                elevation: 0,
                shadowColor: Colors.transparent,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required ImageSource source,
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(source),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            color: const Color(0xFFF8FAFC),
          ),
          child: Row(
            children: [
              // กรอบไอคอนสีสันสดใส
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 14),

              // ข้อความหัวข้อและคำอธิบาย
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
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
                  ],
                ),
              ),

              // ไอคอนลูกศรทางขวา
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
