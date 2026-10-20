import 'package:flutter/material.dart';
import '../models/job.dart';
import '../repositories/job_repository.dart';
import 'job_list_screen.dart';

/// หน้าจอสร้างงานใหม่ (Create Job Screen - หน้าที่ 5)
/// ฟอร์มครบถ้วน พร้อม Validation, Date/Time Picker, Choice Chips, และ Unsaved Changes Dialog
class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers สำหรับฟิลด์ข้อมูล
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  // ค่าของฟิลด์ต่างๆ
  String? _selectedJobType = 'ซ่อมบำรุง';
  String? _selectedClient;
  String _selectedPriority = 'Medium';
  String? _selectedTechnician = 'สมชาย ใจดี (ช่างเทคนิค)';

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isSubmitting = false;
  bool _isFormDirty = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();

    _titleController.addListener(_markAsDirty);
    _descriptionController.addListener(_markAsDirty);
    _locationController.addListener(_markAsDirty);

    // เลือกลูกค้าคนแรกเป็นค่าเริ่มต้น
    _selectedClient = JobRepository.mockClients.first;
    _locationController.text =
        JobRepository.defaultClientLocations[_selectedClient] ?? '';
  }

  void _markAsDirty() {
    if (!_isFormDirty) {
      setState(() {
        _isFormDirty = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// เลือกวันที่นัดหมาย (ไม่สามารถเลือกวันในอดีตได้)
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0066E6),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _isFormDirty = true;
      });
    }
  }

  /// เลือกเวลานัดหมาย
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0066E6),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _isFormDirty = true;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'วันนี้ (${date.day}/${date.month}/${date.year})';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// ตรวจสอบวันที่และเวลาว่าอยู่ในอดีตหรือไม่
  bool _isDateTimeInPast() {
    final now = DateTime.now();
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    // ผ่อนปรน 1 นาที
    return scheduledDateTime.isBefore(now.subtract(const Duration(minutes: 1)));
  }

  /// บันทึกงานใหม่
  Future<void> _handleSaveJob() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isDateTimeInPast()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('เวลานัดหมายต้องไม่อยู่ในอดีต กรุณาเลือกเวลาใหม่'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final repo = JobRepository.instance;
    final style = JobRepository.getStyleForJobType(_selectedJobType!);

    final newJob = Job(
      id: '', // Backend generates sequential ID via DB sequence
      title: _titleController.text.trim(),
      client: _selectedClient!,
      time: _formatTime(_selectedTime),
      date: _formatDate(_selectedDate),
      location: _locationController.text.trim(),
      status: 'รอดำเนินการ',
      statusColor: const Color(0xFFEF4444),
      statusBgColor: const Color(0xFFFEE2E2),
      icon: style['icon'] as IconData,
      iconColor: style['iconColor'] as Color,
      iconBgColor: style['iconBgColor'] as Color,
      priority: _selectedPriority,
      jobType: _selectedJobType!,
      description: _descriptionController.text.trim(),
      technician: _selectedTechnician!,
    );

    try {
      final created = await repo.createJob(newJob);

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      // แสดง SnackBar แจ้งเตือนความสำเร็จพร้อมรหัสที่ได้จาก Backend
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สร้างงานสำเร็จ (รหัส ${created.id})'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // ตรวจสอบ Navigation: นำทางไปหน้า Job List เพื่อดูงานที่เพิ่งสร้าง
      final canPop = Navigator.of(context).canPop();
      if (canPop) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/job_list'),
            builder: (context) => const JobListScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(repo.errorMessage ?? 'เกิดข้อผิดพลาดในการสร้างงาน: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// แสดง Dialog ยืนยันเมื่อต้องการยกเลิกขณะมีข้อมูลที่แก้ไข
  Future<bool> _onWillPop() async {
    if (!_isFormDirty) {
      return true;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ยกเลิกการสร้างงาน?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: const Text(
          'ข้อมูลที่คุณกรอกจะไม่ถูกบันทึก คุณต้องการออกจากหน้านี้หรือไม่?',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('แก้ไขต่อ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยันยกเลิก'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  Future<void> _handleBackPress() async {
    final navigator = Navigator.of(context);
    final shouldPop = await _onWillPop();
    if (shouldPop && mounted) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFormDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
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
            onPressed: _handleBackPress,
          ),
          title: const Text(
            'สร้างงานใหม่',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. ชื่องาน *
                        _buildFieldLabel('ชื่องาน *'),
                        TextFormField(
                          controller: _titleController,
                          textInputAction: TextInputAction.next,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'กรุณาระบุชื่องาน';
                            }
                            return null;
                          },
                          decoration: _inputDecoration('ระบุชื่องาน เช่น ซ่อมเครื่องปรับอากาศ'),
                        ),
                        const SizedBox(height: 16),

                        // 2. ประเภทงาน *
                        _buildFieldLabel('ประเภทงาน *'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedJobType,
                          items: JobRepository.mockJobTypes
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type, style: const TextStyle(fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedJobType = val;
                              _markAsDirty();
                            });
                          },
                          validator: (val) => val == null ? 'กรุณาเลือกประเภทงาน' : null,
                          decoration: _inputDecoration('เลือกประเภทงาน'),
                        ),
                        const SizedBox(height: 16),

                        // 3. ลูกค้า *
                        _buildFieldLabel('ลูกค้า *'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedClient,
                          items: JobRepository.mockClients
                              .map((client) => DropdownMenuItem(
                                    value: client,
                                    child: Text(client, style: const TextStyle(fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedClient = val;
                              if (val != null &&
                                  JobRepository.defaultClientLocations.containsKey(val)) {
                                _locationController.text =
                                    JobRepository.defaultClientLocations[val]!;
                              }
                              _markAsDirty();
                            });
                          },
                          validator: (val) => val == null ? 'กรุณาเลือกลูกค้า' : null,
                          decoration: _inputDecoration('เลือกลูกค้า'),
                        ),
                        const SizedBox(height: 16),

                        // 4. รายละเอียดงาน
                        _buildFieldLabel('รายละเอียดงาน'),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: _inputDecoration(
                            'ระบุรายละเอียดเพิ่มเติม เช่น เครื่องปรับอากาศไม่เย็น, อาการผิดปกติ...',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 5 & 6. วันที่และเวลานัดหมาย (2 คอลัมน์)
                        Row(
                          children: [
                            // วันที่นัดหมาย
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('วันที่นัดหมาย *'),
                                  InkWell(
                                    onTap: _pickDate,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InputDecorator(
                                      decoration: _inputDecoration(
                                        'เลือกวันที่',
                                        prefixIcon: Icons.calendar_today_rounded,
                                      ),
                                      child: Text(
                                        _formatDate(_selectedDate),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // เวลานัดหมาย
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('เวลานัดหมาย *'),
                                  InkWell(
                                    onTap: _pickTime,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InputDecorator(
                                      decoration: _inputDecoration(
                                        'เลือกเวลา',
                                        prefixIcon: Icons.access_time_rounded,
                                      ),
                                      child: Text(
                                        '${_formatTime(_selectedTime)} น.',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 7. สถานที่ปฏิบัติงาน *
                        _buildFieldLabel('สถานที่ปฏิบัติงาน *'),
                        TextFormField(
                          controller: _locationController,
                          maxLines: 2,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'กรุณาระบุสถานที่ปฏิบัติงาน';
                            }
                            return null;
                          },
                          decoration: _inputDecoration(
                            'ที่อยู่หรือสถานที่ปฏิบัติงาน',
                            prefixIcon: Icons.location_on_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 8. ระดับความสำคัญ *
                        _buildFieldLabel('ระดับความสำคัญ *'),
                        _buildPriorityChoiceChips(),
                        const SizedBox(height: 16),

                        // 9. ผู้รับผิดชอบงาน
                        _buildFieldLabel('ผู้รับผิดชอบงาน'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedTechnician,
                          items: JobRepository.mockTechnicians
                              .map((tech) => DropdownMenuItem(
                                    value: tech,
                                    child: Text(tech, style: const TextStyle(fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedTechnician = val;
                              _markAsDirty();
                            });
                          },
                          decoration: _inputDecoration('เลือกช่างเทคนิค'),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Actions: ปุ่มยกเลิก และ ปุ่มบันทึกงาน
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B))
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0066E6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  /// Choice Chips เลือกระดับความสำคัญ: Low, Medium, High
  Widget _buildPriorityChoiceChips() {
    final priorities = [
      {'label': 'Low', 'color': const Color(0xFF10B981)},
      {'label': 'Medium', 'color': const Color(0xFFF59E0B)},
      {'label': 'High', 'color': const Color(0xFFEF4444)},
    ];

    return Row(
      children: priorities.map((p) {
        final label = p['label'] as String;
        final color = p['color'] as Color;
        final isSelected = _selectedPriority == label;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
              selected: isSelected,
              selectedColor: color,
              backgroundColor: color.withValues(alpha: 0.08),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? color : color.withValues(alpha: 0.3),
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPriority = label;
                    _markAsDirty();
                  });
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Bottom Actions Bar
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Row(
        children: [
          // ปุ่มยกเลิก
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final shouldPop = await _onWillPop();
                      if (shouldPop && mounted) {
                        Navigator.of(context).pop();
                      }
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ปุ่มบันทึกงาน
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSaveJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066E6),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'บันทึกงาน',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
