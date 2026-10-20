import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// บริการจัดการการเลือกรูปภาพจากกล้องหรือคลังภาพ (Image Picker Service)
/// แยก Logic การเลือกรูปภาพออกจาก UI เพื่อความสะอาดและทดสอบได้ง่าย (Testability)
class ImagePickerService {
  final ImagePicker _picker;

  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// เลือกรูปภาพตาม ImageSource (Camera หรือ Gallery)
  /// รองรับการจัดการข้อผิดพลาดและส่งคืน XFile? หากสำเร็จ หรือ null หากผู้ใช้ยกเลิก
  Future<XFile?> pickImage(
    ImageSource source, {
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth ?? 1800,
        maxHeight: maxHeight ?? 1800,
        imageQuality: imageQuality ?? 85,
      );
      return file;
    } catch (e, stackTrace) {
      debugPrint('Error picking image from $source: $e\n$stackTrace');
      rethrow;
    }
  }

  /// ถ่ายรูปด้วยกล้องของอุปกรณ์
  Future<XFile?> pickFromCamera() async {
    return pickImage(ImageSource.camera);
  }

  /// เลือกรูปภาพจากแกลเลอรี
  Future<XFile?> pickFromGallery() async {
    return pickImage(ImageSource.gallery);
  }
}
