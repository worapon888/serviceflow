import 'dart:async';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import '../models/job.dart';
import '../models/job_statistics.dart';

/// Single Source of Truth สำหรับจัดการข้อมูลงานบริการ (Field Service Jobs)
/// รองรับการเชื่อมต่อ Spring Boot REST API จริง และมีโหมด Mock สำหรับการทดสอบ (Test Isolation)
class JobRepository extends ChangeNotifier {
  // Singleton Pattern
  static final JobRepository _instance = JobRepository._internal();
  factory JobRepository() => _instance;
  static JobRepository get instance => _instance;

  final List<Job> _jobs = [];
  JobStatistics _statistics = const JobStatistics();
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  JobStatistics get statistics => _statistics;

  JobRepository._internal() {
    if (ApiConfig.useMockMode) {
      _jobs.addAll(Job.mockJobs);
    } else {
      // โหลดข้อมูลสดจาก Spring Boot Backend
      initRemoteData();
    }
  }

  /// รายการงานทั้งหมด (Unmodifiable List)
  List<Job> get jobs => List.unmodifiable(_jobs);

  /// สถิติจำนวนงานสำหรับ Dashboard และ Status Filter Chips
  int get totalCount => ApiConfig.useMockMode ? _jobs.length : _statistics.total;
  int get pendingCount =>
      ApiConfig.useMockMode ? _jobs.where((j) => j.status == 'รอดำเนินการ').length : _statistics.pending;
  int get inProgressCount =>
      ApiConfig.useMockMode ? _jobs.where((j) => j.status == 'กำลังดำเนินการ').length : _statistics.inProgress;
  int get completedCount =>
      ApiConfig.useMockMode ? _jobs.where((j) => j.status == 'เสร็จสิ้น').length : _statistics.completed;
  int get cancelledCount =>
      ApiConfig.useMockMode ? _jobs.where((j) => j.status == 'ยกเลิก').length : _statistics.cancelled;

  /// รายการลูกค้าตัวอย่างสำหรับ Dropdown
  static const List<String> mockClients = [
    'บริษัท ABC จำกัด',
    'บริษัท XYZ จำกัด',
    'ร้านค้า ตัวอย่าง',
    'บ้านลูกค้า คุณสมศรี',
    'คอนโด The Grand Residence',
    'อาคารซีพี ทาวเวอร์',
    'โรงแรม สยามพลาซ่า',
    'โรงพยาบาล บางนาอินเตอร์',
    'ศูนย์อาหาร เมกาซิตี้',
    'โรงเรียนนานาชาติ บริติช',
  ];

  /// แผนที่จับคู่ที่อยู่เริ่มต้นของลูกค้าแต่ละราย
  static const Map<String, String> defaultClientLocations = {
    'บริษัท ABC จำกัด': '123 ถนนสุขุมวิท เขตวัฒนา กรุงเทพฯ',
    'บริษัท XYZ จำกัด': '45 ถนนพหลโยธิน เขตจตุจักร กรุงเทพฯ',
    'ร้านค้า ตัวอย่าง': '88 ถนนสีลม เขตบางรัก กรุงเทพฯ',
    'บ้านลูกค้า คุณสมศรี': '12/4 ซอยทองหล่อ 10 วัฒนา กรุงเทพฯ',
    'คอนโด The Grand Residence': '99 ถนนสาทรใต้ ยานนาวา กรุงเทพฯ',
    'อาคารซีพี ทาวเวอร์': '313 ถนนสีลม บางรัก กรุงเทพฯ',
    'โรงแรม สยามพลาซ่า': '55 ถนนรัชดาภิเษก ดินแดง กรุงเทพฯ',
    'โรงพยาบาล บางนาอินเตอร์': '102 ถนนบางนา-ตราด บางนา กรุงเทพฯ',
    'ศูนย์อาหาร เมกาซิตี้': '39 หมู่ 6 บางนา-ตราด สมุทรปราการ',
    'โรงเรียนนานาชาติ บริติช': '67 ถนนพัฒนาการ สวนหลวง กรุงเทพฯ',
  };

  /// รายการประเภทงาน
  static const List<String> mockJobTypes = [
    'ติดตั้ง',
    'ซ่อมบำรุง',
    'ตรวจสอบ',
    'งานบริการอื่น ๆ',
  ];

  /// รายชื่อช่างเทคนิคผู้รับผิดชอบงาน
  static const List<String> mockTechnicians = [
    'สมชาย ใจดี (ช่างเทคนิค)',
    'วิชัย รักงาน (ช่างไฟฟ้า)',
    'อนันต์ มั่นคง (ช่างเครือข่าย)',
  ];

  /// สุ่มเลือกไอคอนและสีที่เหมาะสมตามประเภทงาน
  static Map<String, dynamic> getStyleForJobType(String jobType) {
    switch (jobType) {
      case 'ติดตั้ง':
        return {
          'icon': Icons.build_rounded,
          'iconColor': const Color(0xFF0066E6),
          'iconBgColor': const Color(0xFFE0EDFE),
        };
      case 'ตรวจสอบ':
        return {
          'icon': Icons.checklist_rounded,
          'iconColor': const Color(0xFF10B981),
          'iconBgColor': const Color(0xFFDCFCE7),
        };
      case 'งานบริการอื่น ๆ':
        return {
          'icon': Icons.handyman_rounded,
          'iconColor': const Color(0xFF8B5CF6),
          'iconBgColor': const Color(0xFFEDE9FE),
        };
      case 'ซ่อมบำรุง':
      default:
        return {
          'icon': Icons.ac_unit_rounded,
          'iconColor': const Color(0xFFF59E0B),
          'iconBgColor': const Color(0xFFFEF3C7),
        };
    }
  }

  /// โหลดข้อมูลครั้งแรกจาก REST API
  Future<void> initRemoteData() async {
    await fetchJobs();
    await fetchStatistics();
  }

  /// โหลดรายการงานจาก GET /api/v1/jobs
  Future<void> fetchJobs({String? status, String? search}) async {
    if (ApiConfig.useMockMode) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': 0,
        'size': 100,
        'sortBy': 'createdAt',
        'sortDir': 'desc',
      };
      if (status != null && status != 'ทั้งหมด') {
        queryParams['status'] = switch (status) {
          'กำลังดำเนินการ' => 'IN_PROGRESS',
          'เสร็จสิ้น' => 'COMPLETED',
          'ยกเลิก' => 'CANCELLED',
          _ => 'PENDING',
        };
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await ApiClient.instance.get('/jobs', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null && data['content'] is List) {
          final list = (data['content'] as List)
              .map((item) => Job.fromJson(item as Map<String, dynamic>))
              .toList();
          _jobs.clear();
          _jobs.addAll(list);
        }
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching jobs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// โหลดสถิติจำนวนงานจาก GET /api/v1/jobs/statistics
  Future<void> fetchStatistics() async {
    if (ApiConfig.useMockMode) return;

    try {
      final response = await ApiClient.instance.get('/jobs/statistics');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          _statistics = JobStatistics.fromJson(data);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
    }
  }

  /// ดึงข้อมูลงานตาม Job ID
  Job? getJobById(String id) {
    try {
      return _jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  /// ดึงข้อมูลงานจาก REST API โดยตรงตาม Job ID (GET /api/v1/jobs/{id})
  Future<Job?> getJobByIdRemote(String id) async {
    if (ApiConfig.useMockMode) {
      return getJobById(id);
    }

    try {
      final encodedId = Uri.encodeComponent(id);
      final response = await ApiClient.instance.get('/jobs/$encodedId');
      if (response.statusCode == 200 && response.data != null) {
        final jobData = response.data['data'] as Map<String, dynamic>;
        final job = Job.fromJson(jobData);
        final index = _jobs.indexWhere((j) => j.id == id);
        if (index != -1) {
          _jobs[index] = job;
        } else {
          _jobs.insert(0, job);
        }
        notifyListeners();
        return job;
      }
    } catch (e) {
      debugPrint('Error fetching job details for $id: $e');
    }
    return getJobById(id);
  }

  /// สร้างรหัสงานใหม่ที่ไม่ซ้ำกับของเดิม (Auto-increment Unique ID) สำหรับ Mock Mode
  String generateNextJobId() {
    int maxId = 0;
    for (final j in _jobs) {
      final digits = RegExp(r'\d+').firstMatch(j.id)?.group(0);
      if (digits != null) {
        final val = int.tryParse(digits) ?? 0;
        if (val > maxId) maxId = val;
      }
    }
    final next = maxId + 1;
    return '#${next.toString().padLeft(5, '0')}';
  }

  /// บันทึกงานใหม่เข้าสู่ Repository (เข้ากันได้กับเทสต์เดิม)
  void addJob(Job newJob) {
    _jobs.insert(0, newJob);
    notifyListeners();
  }

  /// สร้างงานใหม่ไปยัง Spring Boot REST API (POST /api/v1/jobs)
  Future<Job> createJob(Job newJob) async {
    if (ApiConfig.useMockMode) {
      final newId = newJob.id.isNotEmpty ? newJob.id : generateNextJobId();
      final created = newJob.copyWith(id: newId);
      addJob(created);
      return created;
    }

    try {
      final response = await ApiClient.instance.post(
        '/jobs',
        data: newJob.toCreateJson(),
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final created = Job.fromJson(data);
        _jobs.insert(0, created);
        await fetchStatistics();
        notifyListeners();
        return created;
      } else {
        throw ApiException(
          message: 'ไม่สามารถสร้างงานได้ (HTTP ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error creating job: $e');
      rethrow;
    }
  }

  /// ตรวจสอบการเปลี่ยนสถานะตาม Transition Rule
  static bool canTransition(String currentStatus, String targetStatus) {
    if (currentStatus == targetStatus) return true;
    switch (currentStatus) {
      case 'รอดำเนินการ':
        return targetStatus == 'กำลังดำเนินการ' || targetStatus == 'ยกเลิก';
      case 'กำลังดำเนินการ':
        return targetStatus == 'เสร็จสิ้น' || targetStatus == 'ยกเลิก';
      case 'เสร็จสิ้น':
      case 'ยกเลิก':
      default:
        return false;
    }
  }

  /// ตรวจสอบว่าสถานะนี้เป็นสถานะสิ้นสุด (Terminal State) หรือไม่
  static bool isTerminalStatus(String status) {
    return status == 'เสร็จสิ้น' || status == 'ยกเลิก';
  }

  /// อัปเดตสถานะของงานตาม Job ID
  /// คืนค่า `FutureOr<bool>` เพื่อให้รองรับทั้ง Synchronous Test เก่า และ Asynchronous REST API
  FutureOr<bool> updateJobStatus(String id, String newStatus, {String note = ''}) {
    if (ApiConfig.useMockMode) {
      return _updateJobStatusLocal(id, newStatus, note: note);
    }
    return _updateJobStatusRemote(id, newStatus, note: note);
  }

  bool _updateJobStatusLocal(String id, String newStatus, {String note = ''}) {
    final index = _jobs.indexWhere((j) => j.id == id);
    if (index == -1) return false;

    Color statusColor;
    Color statusBgColor;

    switch (newStatus) {
      case 'กำลังดำเนินการ':
        statusColor = const Color(0xFF0284C7);
        statusBgColor = const Color(0xFFE0F2FE);
        break;
      case 'เสร็จสิ้น':
        statusColor = const Color(0xFF10B981);
        statusBgColor = const Color(0xFFD1FAE5);
        break;
      case 'ยกเลิก':
        statusColor = const Color(0xFFDC2626);
        statusBgColor = const Color(0xFFFEE2E2);
        break;
      case 'รอดำเนินการ':
      default:
        statusColor = const Color(0xFFEF4444);
        statusBgColor = const Color(0xFFFEE2E2);
        break;
    }

    final currentJob = _jobs[index];
    _jobs[index] = currentJob.copyWith(
      status: newStatus,
      statusColor: statusColor,
      statusBgColor: statusBgColor,
      statusNote: note.isNotEmpty ? note : currentJob.statusNote,
    );

    notifyListeners();
    return true;
  }

  Future<bool> _updateJobStatusRemote(String id, String newStatus, {String note = ''}) async {
    final index = _jobs.indexWhere((j) => j.id == id);
    if (index == -1) return false;

    final currentJob = _jobs[index];
    final encodedId = Uri.encodeComponent(id);

    try {
      final response = await ApiClient.instance.patch(
        '/jobs/$encodedId/status',
        data: currentJob.toUpdateStatusJson(newStatus, note: note),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final updated = Job.fromJson(data);
        _jobs[index] = updated;
        await fetchStatistics();
        notifyListeners();
        return true;
      }
      return false;
    } on ConflictException catch (conflict) {
      debugPrint('409 Conflict during status update: ${conflict.message}');
      // โหลดสถานะล่าสุดจาก Backend เพื่อซิงค์ข้อมูลให้ผู้ใช้
      await getJobByIdRemote(id);
      _errorMessage = conflict.message;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error updating job status: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// ล้างข้อมูลสำหรับ Unit Tests
  @visibleForTesting
  void clear() {
    _jobs.clear();
    _statistics = const JobStatistics();
    _errorMessage = null;
    notifyListeners();
  }
}
