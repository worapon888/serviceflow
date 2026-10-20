import 'package:flutter/material.dart';
import '../models/job.dart';
import '../repositories/job_repository.dart';
import 'completed_job_screen.dart';

/// ข้อมูลสำหรับตัวเลือกสถานะแต่ละรายการในหน้า Update Job Status
class _StatusOptionItem {
  final String status;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _StatusOptionItem({
    required this.status,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
}

/// หน้าจออัปเดตสถานะงาน (Update Job Status - หน้าที่ 12)
class UpdateJobStatusScreen extends StatefulWidget {
  final String jobId;

  const UpdateJobStatusScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<UpdateJobStatusScreen> createState() => _UpdateJobStatusScreenState();
}

class _UpdateJobStatusScreenState extends State<UpdateJobStatusScreen> {
  final JobRepository _jobRepo = JobRepository.instance;
  final TextEditingController _noteController = TextEditingController();

  late String _selectedStatus;
  bool _isSubmitting = false;

  /// รายการตัวเลือกสถานะ 4 รายการตามภาพต้นแบบหน้าที่ 12
  static const List<_StatusOptionItem> _statusOptions = [
    _StatusOptionItem(
      status: 'รอดำเนินการ',
      title: 'รอดำเนินการ',
      description: 'งานได้รับการมอบหมายแล้ว',
      icon: Icons.assignment_outlined,
      iconColor: Color(0xFF0066E6),
      iconBgColor: Color(0xFFEFF6FF),
    ),
    _StatusOptionItem(
      status: 'กำลังดำเนินการ',
      title: 'กำลังดำเนินการ',
      description: 'เริ่มดำเนินงานหน้างาน',
      icon: Icons.build_circle_outlined,
      iconColor: Color(0xFF0284C7),
      iconBgColor: Color(0xFFE0F2FE),
    ),
    _StatusOptionItem(
      status: 'เสร็จสิ้น',
      title: 'เสร็จสิ้น',
      description: 'ดำเนินงานเสร็จสมบูรณ์',
      icon: Icons.check_circle_outline_rounded,
      iconColor: Color(0xFF10B981),
      iconBgColor: Color(0xFFDCFCE7),
    ),
    _StatusOptionItem(
      status: 'ยกเลิก',
      title: 'ยกเลิก',
      description: 'ยกเลิกงาน',
      icon: Icons.cancel_outlined,
      iconColor: Color(0xFFEF4444),
      iconBgColor: Color(0xFFFEE2E2),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final job = _jobRepo.getJobById(widget.jobId);
    _selectedStatus = job?.status ?? 'รอดำเนินการ';
    if (job != null && job.statusNote.isNotEmpty) {
      _noteController.text = job.statusNote;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// ตรวจสอบว่าสามารถกดปุ่ม "อัปเดตสถานะ" ได้หรือไม่
  bool _canSubmit(Job job) {
    if (_isSubmitting) return false;

    final isTerminal = JobRepository.isTerminalStatus(job.status);
    if (isTerminal) return false;

    // ตรวจสอบว่า Transition ถูกต้องตามกฎหรือไม่
    final isAllowed = JobRepository.canTransition(job.status, _selectedStatus);
    if (!isAllowed) return false;

    // ตรวจสอบว่ามีการเปลี่ยนแปลงหรือไม่ (สถานะเปลี่ยน หรือ หมายเหตุเปลี่ยน)
    final hasStatusChange = _selectedStatus != job.status;
    final hasNoteChange = _noteController.text.trim() != job.statusNote;

    return hasStatusChange || hasNoteChange;
  }

  /// แสดง Dialog ยืนยันการเปลี่ยนสถานะ
  Future<void> _handleUpdateStatus(Job job) async {
    if (!_canSubmit(job)) return;

    final isCancelling = _selectedStatus == 'ยกเลิก';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isCancelling ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
              color: isCancelling ? const Color(0xFFDC2626) : const Color(0xFF0066E6),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'ยืนยันการเปลี่ยนสถานะ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCancelling) ...[
              const Text(
                'คุณต้องการยกเลิกงานนี้ใช่หรือไม่?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'การยกเลิกงานจะไม่สามารถย้อนกลับได้ และงานนี้จะไม่สามารถเปลี่ยนสถานะได้อีก',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
            ] else ...[
              Text(
                'คุณต้องการเปลี่ยนสถานะงานจาก "${job.status}" เป็น "$_selectedStatus" ใช่หรือไม่?',
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.4),
              ),
            ],
            if (_noteController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'หมายเหตุ: ${_noteController.text.trim()}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCancelling ? const Color(0xFFDC2626) : const Color(0xFF0066E6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await _jobRepo.updateJobStatus(
        job.id,
        _selectedStatus,
        note: _noteController.text.trim(),
      );

      if (success && mounted) {
        if (_selectedStatus == 'เสร็จสิ้น') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              settings: const RouteSettings(name: '/completed_job'),
              builder: (context) => CompletedJobScreen(jobId: job.id),
            ),
          );
        } else {
          Navigator.of(context).pop(true);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_jobRepo.errorMessage ?? 'เกิดข้อผิดพลาดในการอัปเดตสถานะงาน'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _jobRepo,
      builder: (context, _) {
        final job = _jobRepo.getJobById(widget.jobId);

        if (job == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('อัปเดตสถานะงาน', style: TextStyle(color: Color(0xFF0F172A))),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 60, color: Color(0xFFEF4444)),
                  const SizedBox(height: 12),
                  Text('ไม่พบข้อมูลงาน (${widget.jobId})', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ย้อนกลับ'),
                  ),
                ],
              ),
            ),
          );
        }

        final isTerminal = JobRepository.isTerminalStatus(job.status);
        final canSubmit = _canSubmit(job);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A), size: 24),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'อัปเดตสถานะงาน',
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // กล่องแจ้งเตือนกรณีงานอยู่ในสถานะสิ้นสุดแล้ว
                        if (isTerminal) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: job.status == 'ยกเลิก'
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: job.status == 'ยกเลิก'
                                    ? const Color(0xFFFCA5A5)
                                    : const Color(0xFF86EFAC),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  job.status == 'ยกเลิก'
                                      ? Icons.cancel_outlined
                                      : Icons.check_circle_outline_rounded,
                                  color: job.status == 'ยกเลิก'
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF16A34A),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'งานนี้มีสถานะ "${job.status}" ซึ่งเป็นสถานะสิ้นสุดแล้ว ไม่สามารถเปลี่ยนแปลงสถานะได้',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: job.status == 'ยกเลิก'
                                          ? const Color(0xFF991B1B)
                                          : const Color(0xFF166534),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // หัวข้อ "เลือกสถานะ"
                        const Text(
                          'เลือกสถานะ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // รายการ Vertical Selection Cards 4 รายการ
                        ..._statusOptions.map((item) {
                          return _buildStatusOptionCard(job, item, isTerminal);
                        }),

                        const SizedBox(height: 20),

                        // ส่วนหมายเหตุ (TextArea)
                        const Text(
                          'หมายเหตุ (ถ้ามี)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),

                        TextField(
                          controller: _noteController,
                          maxLines: 4,
                          enabled: !isTerminal,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            hintText: 'ระบุเหตุผลหรือรายละเอียดเพิ่มเติม',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: isTerminal ? const Color(0xFFF1F5F9) : Colors.white,
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
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // แถบปุ่ม Action ด้านล่าง (Bottom Action Bar)
                Container(
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
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: canSubmit ? () => _handleUpdateStatus(job) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066E6),
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'อัปเดตสถานะ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// การ์ดตัวเลือกสถานะแต่ละรายการ
  Widget _buildStatusOptionCard(Job job, _StatusOptionItem item, bool isTerminal) {
    final isSelected = _selectedStatus == item.status;
    final isCurrent = job.status == item.status;

    // กฎการเปลี่ยนสถานะ:
    // รอดำเนินการ -> กำลังดำเนินการ หรือ ยกเลิก
    // กำลังดำเนินการ -> เสร็จสิ้น หรือ ยกเลิก
    // สิ้นสุดแล้ว -> ไม่อนุญาต
    final isAllowed = JobRepository.canTransition(job.status, item.status);
    final isEnabled = !isTerminal && isAllowed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  setState(() {
                    _selectedStatus = item.status;
                  });
                }
              : null,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF0F7FF)
                  : (isEnabled ? Colors.white : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF0066E6)
                    : (isEnabled ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0066E6).withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.45,
              child: Row(
                children: [
                  // Radio Indicator ด้านซ้าย
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0066E6)
                            : (isEnabled ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
                        width: isSelected ? 2 : 1.5,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0066E6),
                              ),
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 14),

                  // ไอคอนสถานะในกรอบมุมมน
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.iconColor,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ชื่อสถานะและคำอธิบาย
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isEnabled ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isEnabled ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ป้ายบอกสถานะปัจจุบัน (ถ้าใช่)
                  if (isCurrent) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ปัจจุบัน',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
