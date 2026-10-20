import 'package:flutter/material.dart';

/// สถานะของงานบริการ
enum JobStatus {
  pending('รอดำเนินการ'),
  inProgress('กำลังดำเนินการ'),
  completed('เสร็จสิ้น'),
  cancelled('ยกเลิก');

  final String label;
  const JobStatus(this.label);

  static JobStatus fromString(String str) {
    final clean = str.trim().toUpperCase();
    if (clean == 'กำลังดำเนินการ' || clean == 'IN_PROGRESS' || clean == 'INPROGRESS') {
      return JobStatus.inProgress;
    } else if (clean == 'เสร็จสิ้น' || clean == 'COMPLETED') {
      return JobStatus.completed;
    } else if (clean == 'ยกเลิก' || clean == 'CANCELLED') {
      return JobStatus.cancelled;
    } else {
      return JobStatus.pending;
    }
  }

  Color get color {
    switch (this) {
      case JobStatus.pending:
        return const Color(0xFFEF4444);
      case JobStatus.inProgress:
        return const Color(0xFF0284C7);
      case JobStatus.completed:
        return const Color(0xFF10B981);
      case JobStatus.cancelled:
        return const Color(0xFFDC2626);
    }
  }

  Color get bgColor {
    switch (this) {
      case JobStatus.pending:
        return const Color(0xFFFEE2E2);
      case JobStatus.inProgress:
        return const Color(0xFFE0F2FE);
      case JobStatus.completed:
        return const Color(0xFFD1FAE5);
      case JobStatus.cancelled:
        return const Color(0xFFFEE2E2);
    }
  }
}

/// โมเดลข้อมูลงานบริการ (Field Service Job)
class Job {
  final String id;
  final String title;
  final String client;
  final String time;
  final String date;
  final String location;
  final String status;
  final Color statusColor;
  final Color statusBgColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String priority; // 'Low', 'Medium', 'High'
  final String jobType;
  final String description;
  final String technician;
  final String statusNote;
  final int version;

  const Job({
    required this.id,
    required this.title,
    required this.client,
    required this.time,
    this.date = 'วันนี้',
    this.location = 'กรุงเทพมหานคร',
    required this.status,
    required this.statusColor,
    required this.statusBgColor,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.priority = 'Medium',
    this.jobType = 'ซ่อมบำรุง',
    this.description = 'รายละเอียดการปฏิบัติงาน',
    this.technician = 'สมชาย ใจดี',
    this.statusNote = '',
    this.version = 0,
  });

  Color get priorityColor {
    switch (priority) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Medium':
        return const Color(0xFFF59E0B);
      case 'Low':
      default:
        return const Color(0xFF10B981);
    }
  }

  Color get priorityBgColor {
    switch (priority) {
      case 'High':
        return const Color(0xFFFEE2E2);
      case 'Medium':
        return const Color(0xFFFEF3C7);
      case 'Low':
      default:
        return const Color(0xFFDCFCE7);
    }
  }

  Job copyWith({
    String? id,
    String? title,
    String? client,
    String? time,
    String? date,
    String? location,
    String? status,
    Color? statusColor,
    Color? statusBgColor,
    IconData? icon,
    Color? iconColor,
    Color? iconBgColor,
    String? priority,
    String? jobType,
    String? description,
    String? technician,
    String? statusNote,
    int? version,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      client: client ?? this.client,
      time: time ?? this.time,
      date: date ?? this.date,
      location: location ?? this.location,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
      statusBgColor: statusBgColor ?? this.statusBgColor,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      iconBgColor: iconBgColor ?? this.iconBgColor,
      priority: priority ?? this.priority,
      jobType: jobType ?? this.jobType,
      description: description ?? this.description,
      technician: technician ?? this.technician,
      statusNote: statusNote ?? this.statusNote,
      version: version ?? this.version,
    );
  }

  /// แปลง JSON จาก Spring Boot REST API เข้าเป็น Job Model
  factory Job.fromJson(Map<String, dynamic> json) {
    final statusStr = json['statusLabel']?.toString() ??
        json['status']?.toString() ??
        'รอดำเนินการ';
    final jobStatus = JobStatus.fromString(statusStr);
    final jobTypeStr = (json['jobType'] ?? 'ซ่อมบำรุง').toString();
    final style = _getStyleForJobType(jobTypeStr);

    return Job(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      client: (json['client'] ?? '').toString(),
      time: (json['appointmentTime'] ?? json['time'] ?? '09:00').toString(),
      date: (json['appointmentDate'] ?? json['date'] ?? 'วันนี้').toString(),
      location: (json['location'] ?? 'กรุงเทพมหานคร').toString(),
      status: jobStatus.label,
      statusColor: jobStatus.color,
      statusBgColor: jobStatus.bgColor,
      icon: style['icon'] as IconData,
      iconColor: style['iconColor'] as Color,
      iconBgColor: style['iconBgColor'] as Color,
      priority: (json['priority'] ?? 'Medium').toString(),
      jobType: jobTypeStr,
      description: (json['description'] ?? '').toString(),
      technician: (json['technician'] ?? 'สมชาย ใจดี').toString(),
      statusNote: (json['statusNote'] ?? '').toString(),
      version: (json['version'] as num?)?.toInt() ?? 0,
    );
  }

  /// แปลงเป็น JSON สำหรับสร้างงานใหม่ส่งไปยัง Spring Boot (POST /api/v1/jobs)
  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'client': client,
      'appointmentDate': date,
      'appointmentTime': time,
      'location': location,
      'priority': priority,
      'jobType': jobType,
      'description': description,
      'technician': technician,
    };
  }

  /// แปลงเป็น JSON สำหรับอัปเดตสถานะงานส่งไปยัง Spring Boot (PATCH /api/v1/jobs/{id}/status)
  Map<String, dynamic> toUpdateStatusJson(String targetStatus, {String note = ''}) {
    final backendStatus = switch (targetStatus) {
      'กำลังดำเนินการ' => 'IN_PROGRESS',
      'เสร็จสิ้น' => 'COMPLETED',
      'ยกเลิก' => 'CANCELLED',
      _ => 'PENDING',
    };
    return {
      'status': backendStatus,
      'note': note,
      'version': version,
    };
  }

  static Map<String, dynamic> _getStyleForJobType(String jobType) {
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

  /// Mock Data 24 รายการ สอดคล้องกับตัวเลข 24 / 8 / 10 / 6
  static List<Job> get mockJobs => [
        // 1. รอดำเนินการ (Pending) - 1/8
        const Job(
          id: '#00028',
          title: 'ตรวจล้างแอร์',
          client: 'บริษัท ABC จำกัด',
          time: '09:00',
          date: 'วันนี้',
          location: '123 ถนนสุขุมวิท เขตวัฒนา กรุงเทพฯ',
          status: 'รอดำเนินการ',
          statusColor: Color(0xFFEF4444),
          statusBgColor: Color(0xFFFEE2E2),
          icon: Icons.ac_unit_rounded,
          iconColor: Color(0xFFF59E0B),
          iconBgColor: Color(0xFFFEF3C7),
          priority: 'High',
        ),

        // 2. กำลังดำเนินการ (In Progress) - 1/10
        const Job(
          id: '#00026',
          title: 'ติดตั้ง Router',
          client: 'บริษัท XYZ จำกัด',
          time: '11:00',
          date: 'วันนี้',
          location: '45 ถนนพหลโยธิน เขตจตุจักร กรุงเทพฯ',
          status: 'กำลังดำเนินการ',
          statusColor: Color(0xFF0284C7),
          statusBgColor: Color(0xFFE0F2FE),
          icon: Icons.router_rounded,
          iconColor: Color(0xFFF43F5E),
          iconBgColor: Color(0xFFFFE4E6),
          priority: 'Medium',
        ),

        // 3. เสร็จสิ้น (Completed) - 1/6
        const Job(
          id: '#00025',
          title: 'ตรวจระบบไฟฟ้า',
          client: 'ร้านค้า ตัวอย่าง',
          time: '14:00',
          date: 'วันนี้',
          location: '88 ถนนสีลม เขตบางรัก กรุงเทพฯ',
          status: 'เสร็จสิ้น',
          statusColor: Color(0xFF10B981),
          statusBgColor: Color(0xFFD1FAE5),
          icon: Icons.bolt_rounded,
          iconColor: Color(0xFF10B981),
          iconBgColor: Color(0xFFDCFCE7),
          priority: 'Low',
        ),

        // 4. รอดำเนินการ - 2/8
        const Job(
          id: '#00024',
          title: 'ซ่อมตู้เย็น',
          client: 'บ้านลูกค้า คุณสมศรี',
          time: '15:00',
          date: 'วันนี้',
          location: '12/4 ซอยทองหล่อ 10 กรุงเทพฯ',
          status: 'รอดำเนินการ',
          statusColor: Color(0xFFEF4444),
          statusBgColor: Color(0xFFFEE2E2),
          icon: Icons.kitchen_rounded,
          iconColor: Color(0xFFF59E0B),
          iconBgColor: Color(0xFFFEF3C7),
          priority: 'Medium',
        ),

        // 5. กำลังดำเนินการ - 2/10
        const Job(
          id: '#00023',
          title: 'ติดตั้งกล้องวงจรปิด',
          client: 'คอนโด The Grand Residence',
          time: '10:00',
          date: 'วันนี้',
          location: '99 ถนนสาทรใต้ ยานนาวา กรุงเทพฯ',
          status: 'กำลังดำเนินการ',
          statusColor: Color(0xFF0284C7),
          statusBgColor: Color(0xFFE0F2FE),
          icon: Icons.videocam_rounded,
          iconColor: Color(0xFF0284C7),
          iconBgColor: Color(0xFFE0F2FE),
          priority: 'High',
        ),

        // 6. กำลังดำเนินการ - 3/10
        const Job(
          id: '#00022',
          title: 'ตรวจเช็คแอร์ส่วนกลาง',
          client: 'อาคารซีพี ทาวเวอร์',
          time: '08:30',
          date: 'วันนี้',
          location: '313 ถนนสีลม บางรัก กรุงเทพฯ',
          status: 'กำลังดำเนินการ',
          statusColor: Color(0xFF0284C7),
          statusBgColor: Color(0xFFE0F2FE),
          icon: Icons.ac_unit_rounded,
          iconColor: Color(0xFFF59E0B),
          iconBgColor: Color(0xFFFEF3C7),
          priority: 'Medium',
        ),

        // 7. รอดำเนินการ - 3/8
        const Job(
          id: '#00021',
          title: 'ซ่อมระบบท่อน้ำดี',
          client: 'โรงแรม สยามพลาซ่า',
          time: '13:00',
          date: 'วันนี้',
          location: '55 ถนนรัชดาภิเษก ดินแดง กรุงเทพฯ',
          status: 'รอดำเนินการ',
          statusColor: Color(0xFFEF4444),
          statusBgColor: Color(0xFFFEE2E2),
          icon: Icons.water_drop_rounded,
          iconColor: Color(0xFF0284C7),
          iconBgColor: Color(0xFFE0F2FE),
          priority: 'High',
        ),

        // 8. เสร็จสิ้น - 2/6
        const Job(
          id: '#00020',
          title: 'เปลี่ยนแผ่นกรองอากาศ',
          client: 'บริษัท มีเดียพลัส จำกัด',
          time: '16:30',
          date: 'วันนี้',
          location: '78 ถนนเพชรบุรีตัดใหม่ กรุงเทพฯ',
          status: 'เสร็จสิ้น',
          statusColor: Color(0xFF10B981),
          statusBgColor: Color(0xFFD1FAE5),
          icon: Icons.air_rounded,
          iconColor: Color(0xFF10B981),
          iconBgColor: Color(0xFFDCFCE7),
          priority: 'Low',
        ),

        // 9. กำลังดำเนินการ - 4/10
        const Job(
          id: '#00019',
          title: 'ตรวจเช็คลิฟต์โดยสาร',
          client: 'อาคารไทยพาณิชย์ปาร์ค',
          time: '09:30',
          date: 'วันนี้',
          location: '19 ถนนรัชโยธิน จตุจักร กรุงเทพฯ',
          status: 'กำลังดำเนินการ',
          statusColor: Color(0xFF0284C7),
          statusBgColor: Color(0xFFE0F2FE),
          icon: Icons.elevator_rounded,
          iconColor: Color(0xFFF43F5E),
          iconBgColor: Color(0xFFFFE4E6),
          priority: 'High',
        ),

        // 10. รอดำเนินการ - 4/8
        const Job(
          id: '#00018',
          title: 'ติดตั้งสายไฟตู้เมน',
          client: 'ศูนย์อาหาร เมกาซิตี้',
          time: '11:30',
          date: 'วันนี้',
          location: '39 หมู่ 6 บางนา-ตราด สมุทรปราการ',
          status: 'รอดำเนินการ',
          statusColor: Color(0xFFEF4444),
          statusBgColor: Color(0xFFFEE2E2),
          icon: Icons.electrical_services_rounded,
          iconColor: Color(0xFFF59E0B),
          iconBgColor: Color(0xFFFEF3C7),
          priority: 'Medium',
        ),

        // 11. กำลังดำเนินการ - 5/10
        const Job(
          id: '#00017',
          title: 'ล้างเครื่องฟอกอากาศ',
          client: 'โรงพยาบาล บางนาอินเตอร์',
          time: '14:30',
          date: 'วันนี้',
          location: '102 ถนนบางนา-ตราด บางนา กรุงเทพฯ',
          status: 'กำลังดำเนินการ',
          statusColor: Color(0xFF0284C7),
          statusBgColor: Color(0xFFE0F2FE),
          icon: Icons.cleaning_services_rounded,
          iconColor: Color(0xFF10B981),
          iconBgColor: Color(0xFFDCFCE7),
          priority: 'Low',
        ),

        // 12. รอดำเนินการ - 5/8
        const Job(
          id: '#00016',
          title: 'ซ่อมปั๊มน้ำบ้านพัก',
          client: 'มบ. พฤกษาวิลล์',
          time: '16:00',
          date: 'วันนี้',
          location: '22/8 ซอยรามคำแหง 118 สะพานสูง กรุงเทพฯ',
          status: 'รอดำเนินการ',
          statusColor: Color(0xFFEF4444),
          statusBgColor: Color(0xFFFEE2E2),
          icon: Icons.plumbing_rounded,
          iconColor: Color(0xFF0284C7),
          iconBgColor: Color(0xFFE0F2FE),
          priority: 'Low',
        ),

        // 13. กำลังดำเนินการ - 6/10
        const Job(
          id: '#00015',
          title: 'ติดตั้งสวิตช์ไฟอัจฉริยะ',
          client: 'บริษัท นวัตกรรมไทย จำกัด',
          time: '10:30',
          date: 'วันนี้',
          location: '155 ถนนพระราม 9 ห้วยขวาง กรุงเทพฯ',
          status: 'กำลังดำเนินการ',
          statusColor: Color(0xFF0284C7),
          statusBgColor: Color(0xFFE0F2FE),
          icon: Icons.lightbulb_outline_rounded,
          iconColor: Color(0xFFF59E0B),
          iconBgColor: Color(0xFFFEF3C7),
          priority: 'Medium',
        ),

        // 14. เสร็จสิ้น - 3/6
        const Job(
          id: '#00014',
          title: 'ตรวจระบบดับเพลิง',
          client: 'คลังสินค้า บางพลีโลจิสติกส์',
          time: '13:30',
          date: 'วันนี้',
          location: '89 ถนนกิ่งแก้ว บางพลี สมุทรปราการ',
          status: 'เสร็จสิ้น',
          statusColor: Color(0xFF10B981),
          statusBgColor: Color(0xFFD1FAE5),
          icon: Icons.fire_extinguisher_rounded,
          iconColor: Color(0xFFEF4444),
          iconBgColor: Color(0xFFFEE2E2),
          priority: 'High',
        ),

        // 15. กำลังดำเนินการ - 7/10
        const Job(
          id: '#00013',
          title: 'เปลี่ยนคอมเพรสเซอร์แอร์',
          client: 'โรงเรียนนานาชาติ บริติช',
          time: '09:00',
          date: 'วันนี้',
          location: '67 ถนนพัฒนาการ สวนหลวง กรุงเทพฯ',
          status: 'กำลังดำเนินการ',
          statusColor: Color(0xFF0284C7),
          statusBgColor: Color(0xFFE0F2FE),
          icon: Icons.ac_unit_rounded,
          iconColor: Color(0xFF0284C7),
          iconBgColor: Color(0xFFE0F2FE),
          priority: 'High',
        ),

        // 16. รอดำเนินการ - 6/8
        const Job(
          id: '#00012',
          title: 'เซ็ตอัพ Access Point',
          client: 'บริษัท สยามเทค จำกัด',
          time: '11:00',
          date: 'วันนี้',
          location: '40 ถนนพระราม 4 คลองเตย กรุงเทพฯ',
          status: 'รอดำเนินการ',
          statusColor: Color(0xFFEF4444),
          statusBgColor: Color(0xFFFEE2E2),
          icon: Icons.wifi_rounded,
          iconColor: Color(0xFF0284C7),
          iconBgColor: Color(0xFFE0F2FE),
          priority: 'Low',
        ),

        // 17. เสร็จสิ้น - 4/6
        const Job(
          id: '#00011',
          title: 'ตรวจเช็คแผงโซลาร์เซลล์',
          client: 'ฟาร์มเกษตรอินทรีย์ ปทุมธานี',
          time: '14:00',
          date: 'วันนี้',
          location: '12 หมู่ 2 คลองหลวง ปทุมธานี',
          status: 'เสร็จสิ้น',
          statusColor: Color(0xFF10B981),
          statusBgColor: Color(0xFFD1FAE5),
          icon: Icons.wb_sunny_rounded,
          iconColor: Color(0xFFF59E0B),
          iconBgColor: Color(0xFFFEF3C7),
          priority: 'Medium',
        ),

        // 18. รอดำเนินการ - 7/8
        const Job(
          id: '#00010',
          title: 'ซ่อมมอเตอร์ประตูม้วน',
          client: 'ร้านทองเยาวราช สาขา 2',
          time: '15:30',
          date: 'วันนี้',
          location: '202 ถนนเยาวราช สัมพันธวงศ์ กรุงเทพฯ',
          status: 'รอดำเนินการ',
          statusColor: Color(0xFFEF4444),
          statusBgColor: Color(0xFFFEE2E2),
          icon: Icons.door_sliding_rounded,
          iconColor: Color(0xFFF43F5E),
          iconBgColor: Color(0xFFFFE4E6),
          priority: 'High',
        ),

        // 19. กำลังดำเนินการ - 8/10
        const Job(
          id: '#00009',
          title: 'ติดตั้งเบรกเกอร์ไฟฟ้า',
          client: 'โรงงาน ชลบุรีโปรดักส์',
          time: '08:30',
          date: 'วันนี้',
          location: '70 นิคมอมตะนคร เมืองชลบุรี ชลบุรี',
          status: 'กำลังดำเนินการ',
          statusColor: Color(0xFF0284C7),
          statusBgColor: Color(0xFFE0F2FE),
          icon: Icons.power_rounded,
          iconColor: Color(0xFFF59E0B),
          iconBgColor: Color(0xFFFEF3C7),
          priority: 'Medium',
        ),

        // 20. เสร็จสิ้น - 5/6
        const Job(
          id: '#00008',
          title: 'ตรวจวัดแรงดันน้ำประปา',
          client: 'อาคารชุด อารีย์วิลล์',
          time: '10:45',
          date: 'วันนี้',
          location: '33 ซอยอารีย์สัมพันธ์ พญาไท กรุงเทพฯ',
          status: 'เสร็จสิ้น',
          statusColor: Color(0xFF10B981),
          statusBgColor: Color(0xFFD1FAE5),
          icon: Icons.speed_rounded,
          iconColor: Color(0xFF0284C7),
          iconBgColor: Color(0xFFE0F2FE),
          priority: 'Low',
        ),

        // 21. กำลังดำเนินการ - 9/10
        const Job(
          id: '#00007',
          title: 'ซ่อมแอร์ไม่เย็น',
          client: 'คลินิกทันตกรรมสไมล์',
          time: '13:15',
          date: 'วันนี้',
          location: '18 ถนนลาดพร้าว จตุจักร กรุงเทพฯ',
          status: 'กำลังดำเนินการ',
          statusColor: Color(0xFF0284C7),
          statusBgColor: Color(0xFFE0F2FE),
          icon: Icons.ac_unit_rounded,
          iconColor: Color(0xFFF59E0B),
          iconBgColor: Color(0xFFFEF3C7),
          priority: 'Medium',
        ),

        // 22. รอดำเนินการ - 8/8
        const Job(
          id: '#00006',
          title: 'เชื่อมต่อสายใยแก้ว Fiber',
          client: 'ศูนย์ข้อมูล ทีซีซี ดาต้าเซ็นเตอร์',
          time: '15:45',
          date: 'วันนี้',
          location: '555 ถนนวิภาวดีรังสิต จตุจักร กรุงเทพฯ',
          status: 'รอดำเนินการ',
          statusColor: Color(0xFFEF4444),
          statusBgColor: Color(0xFFFEE2E2),
          icon: Icons.settings_ethernet_rounded,
          iconColor: Color(0xFF0284C7),
          iconBgColor: Color(0xFFE0F2FE),
          priority: 'High',
        ),

        // 23. กำลังดำเนินการ - 10/10
        const Job(
          id: '#00005',
          title: 'ตรวจสอบระบบสำรองไฟ UPS',
          client: 'ธนาคาร กรุงไทย สาขาใหญ่',
          time: '11:15',
          date: 'วันนี้',
          location: '100 ถนนเจริญกรุง สัมพันธวงศ์ กรุงเทพฯ',
          status: 'กำลังดำเนินการ',
          statusColor: Color(0xFF0284C7),
          statusBgColor: Color(0xFFE0F2FE),
          icon: Icons.battery_charging_full_rounded,
          iconColor: Color(0xFF10B981),
          iconBgColor: Color(0xFFDCFCE7),
          priority: 'High',
        ),

        // 24. เสร็จสิ้น - 6/6
        const Job(
          id: '#00004',
          title: 'ล้างแอร์ติดผนัง 3 เครื่อง',
          client: 'อพาร์ทเมนท์ รัชดาเพลส',
          time: '16:15',
          date: 'วันนี้',
          location: '88/1 ซอยรัชดาภิเษก 32 จตุจักร กรุงเทพฯ',
          status: 'เสร็จสิ้น',
          statusColor: Color(0xFF10B981),
          statusBgColor: Color(0xFFD1FAE5),
          icon: Icons.ac_unit_rounded,
          iconColor: Color(0xFF10B981),
          iconBgColor: Color(0xFFDCFCE7),
          priority: 'Low',
        ),
      ];
}
