import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../repositories/job_photo_repository.dart';

/// วิดเจ็ตสำหรับแสดงรูปภาพที่มีการป้องกันสิทธิ์ (Protected Site Photos)
/// โดยดาวน์โหลดข้อมูลภาพผ่าน JobPhotoRepository / ApiClient พร้อมแนบ Bearer Token
/// และใช้หน่วยความจำแคชเพื่อความรวดเร็ว ไม่กระพริบ และประหยัด Bandwidth
class AuthenticatedImage extends StatefulWidget {
  final String jobId;
  final String photoId;
  final String? localPath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;
  final Widget? loadingWidget;

  const AuthenticatedImage({
    super.key,
    required this.jobId,
    required this.photoId,
    this.localPath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    this.loadingWidget,
  });

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  Future<Uint8List>? _bytesFuture;
  Uint8List? _cachedBytes;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  @override
  void didUpdateWidget(covariant AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoId != widget.photoId || oldWidget.jobId != widget.jobId) {
      _loadBytes();
    }
  }

  void _loadBytes() {
    // 1. ตรวจสอบว่ามีแคชใน Repository หรือไม่
    final cached = JobPhotoRepository.instance.getCachedBytes(widget.photoId);
    if (cached != null) {
      _cachedBytes = cached;
      _bytesFuture = null;
      return;
    }

    _cachedBytes = null;
    // 2. ถ้ามีไฟล์ในเครื่องและไม่ใช่ Web
    if (widget.localPath != null &&
        !kIsWeb &&
        File(widget.localPath!).existsSync()) {
      return;
    }

    // 3. ดึงจากเซิร์ฟเวอร์แบบ Asynchronous
    if (widget.jobId.isNotEmpty && widget.photoId.isNotEmpty) {
      _bytesFuture = JobPhotoRepository.instance.getPhotoBytes(widget.jobId, widget.photoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. ถ้ามีไฟล์ Local อยู่ในเครื่อง
    if (widget.localPath != null &&
        !kIsWeb &&
        File(widget.localPath!).existsSync()) {
      return Image.file(
        File(widget.localPath!),
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }

    // 2. ถ้ามีไบต์อยู่ในแคชหน่วยความจำแล้ว แสดงทันที
    if (_cachedBytes != null) {
      return Image.memory(
        _cachedBytes!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }

    // 3. ดาวน์โหลดจาก API
    if (_bytesFuture != null) {
      return FutureBuilder<Uint8List>(
        future: _bytesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return widget.loadingWidget ?? _buildLoadingWidget();
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return widget.errorWidget ?? _buildErrorWidget();
          }

          return Image.memory(
            snapshot.data!,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            errorBuilder: (context, error, stackTrace) =>
                widget.errorWidget ?? _buildErrorWidget(),
          );
        },
      );
    }

    return widget.errorWidget ?? _buildErrorWidget();
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0066E6)),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          size: 28,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
