import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_practice/config/api_config.dart';
import 'package:flutter_practice/core/network/api_client.dart';
import 'package:flutter_practice/core/network/api_exceptions.dart';
import 'package:flutter_practice/models/job.dart';
import 'package:flutter_practice/models/job_statistics.dart';
import 'package:flutter_practice/repositories/auth_repository.dart';
import 'package:flutter_practice/repositories/job_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  group('Job Model JSON Serialization Tests', () {
    test('Job.fromJson maps correctly from Spring Boot JobResponse JSON', () {
      final json = {
        'id': '#00001',
        'title': 'ตรวจสอบระบบไฟฟ้าหลัก',
        'jobType': 'ตรวจสอบ',
        'description': 'ตรวจเช็กตู้ MDB ประจำเดือน',
        'client': 'อาคารสุขุมวิท คอมเพล็กซ์',
        'technician': 'สมชาย ใจดี',
        'appointmentDate': 'วันนี้',
        'appointmentTime': '09:00',
        'location': 'ชั้น 1 อาคารสุขุมวิท คอมเพล็กซ์',
        'priority': 'High',
        'status': 'PENDING',
        'statusLabel': 'รอดำเนินการ',
        'statusNote': 'รออนุมัติเข้าพื้นที่',
        'version': 3,
      };

      final job = Job.fromJson(json);
      expect(job.id, '#00001');
      expect(job.title, 'ตรวจสอบระบบไฟฟ้าหลัก');
      expect(job.status, 'รอดำเนินการ');
      expect(job.jobType, 'ตรวจสอบ');
      expect(job.version, 3);
      expect(job.priority, 'High');
    });

    test('Job.toCreateJson formats request payload for Spring Boot', () {
      final style = JobRepository.getStyleForJobType('ติดตั้ง');
      final job = Job(
        id: '',
        title: 'ติดตั้งมิเตอร์ไฟฟ้าใหม่',
        client: 'นายกิตติคุณ มั่นคง',
        time: '14:00',
        date: 'พรุ่งนี้',
        location: '99/42 ซอยอารีย์',
        status: 'รอดำเนินการ',
        statusColor: const Color(0xFFEF4444),
        statusBgColor: const Color(0xFFFEE2E2),
        icon: style['icon'] as IconData,
        iconColor: style['iconColor'] as Color,
        iconBgColor: style['iconBgColor'] as Color,
        priority: 'High',
        jobType: 'ติดตั้ง',
        description: 'ติดตั้งหม้อแปลงไฟฟ้า 50 kVA',
        technician: 'สมชาย ใจดี',
      );

      final json = job.toCreateJson();
      expect(json['title'], 'ติดตั้งมิเตอร์ไฟฟ้าใหม่');
      expect(json['client'], 'นายกิตติคุณ มั่นคง');
      expect(json['appointmentTime'], '14:00');
      expect(json['appointmentDate'], 'พรุ่งนี้');
      expect(json['priority'], 'High');
      expect(json['jobType'], 'ติดตั้ง');
      expect(json['description'], 'ติดตั้งหม้อแปลงไฟฟ้า 50 kVA');
      expect(json['technician'], 'สมชาย ใจดี');
      expect(json.containsKey('id'), false); // Spring Boot generates ID
    });

    test('Job.toUpdateStatusJson creates proper status payload with version', () {
      final style = JobRepository.getStyleForJobType('ซ่อมบำรุง');
      final job = Job(
        id: '#00005',
        title: 'ทดสอบ',
        client: 'ลูกค้า',
        time: '09:00',
        status: 'รอดำเนินการ',
        statusColor: const Color(0xFFEF4444),
        statusBgColor: const Color(0xFFFEE2E2),
        icon: style['icon'] as IconData,
        iconColor: style['iconColor'] as Color,
        iconBgColor: style['iconBgColor'] as Color,
        version: 2,
      );

      final inProgressJson = job.toUpdateStatusJson('กำลังดำเนินการ', note: 'เริ่มทำ');
      expect(inProgressJson['status'], 'IN_PROGRESS');
      expect(inProgressJson['note'], 'เริ่มทำ');
      expect(inProgressJson['version'], 2);

      final completedJson = job.toUpdateStatusJson('เสร็จสิ้น');
      expect(completedJson['status'], 'COMPLETED');
      expect(completedJson['version'], 2);

      final cancelledJson = job.toUpdateStatusJson('ยกเลิก', note: 'ลูกค้ายกเลิกนัด');
      expect(cancelledJson['status'], 'CANCELLED');
      expect(cancelledJson['note'], 'ลูกค้ายกเลิกนัด');
      expect(cancelledJson['version'], 2);
    });
  });

  group('JobStatistics Model Tests', () {
    test('JobStatistics.fromJson maps response correctly', () {
      final json = {
        'total': 24,
        'pending': 8,
        'inProgress': 10,
        'completed': 6,
        'cancelled': 0,
      };

      final stats = JobStatistics.fromJson(json);
      expect(stats.total, 24);
      expect(stats.pending, 8);
      expect(stats.inProgress, 10);
      expect(stats.completed, 6);
      expect(stats.cancelled, 0);
    });
  });

  group('ApiException Tests', () {
    test('ConflictException has 409 status code', () {
      const conflict = ConflictException(
        message: 'ข้อมูลถูกแก้ไขโดยผู้อื่น กรุณารีเฟรชเพื่อดูข้อมูลล่าสุด',
      );
      expect(conflict.statusCode, 409);
    });

    test('ValidationException has 400 status code', () {
      const validation = ValidationException(
        message: 'Validation failed',
        fieldErrors: {'title': 'Job title is required'},
      );
      expect(validation.statusCode, 400);
      expect(validation.fieldErrors?['title'], 'Job title is required');
    });
  });

  group('JobRepository Remote API Integration Tests', () {
    setUp(() async {
      HttpOverrides.global = null;
      ApiConfig.useMockMode = false;
      JobRepository.instance.clear();
      try {
        await AuthRepository.instance.login('dispatcher', 'Dispatcher@123');
      } catch (_) {}
    });

    tearDown(() {
      ApiClient.instance.clearAuthToken();
      ApiConfig.useMockMode = true; // reset to default mock mode for unit test isolation
    });

    test('fetchStatistics fetches live data from Spring Boot', () async {
      await JobRepository.instance.fetchStatistics();
      final stats = JobRepository.instance.statistics;
      expect(stats.total, greaterThanOrEqualTo(20));
      expect(JobRepository.instance.totalCount, greaterThanOrEqualTo(20));
    });

    test('fetchJobs fetches real jobs list from Spring Boot and PostgreSQL', () async {
      await JobRepository.instance.fetchJobs();
      final jobs = JobRepository.instance.jobs;
      expect(jobs.isNotEmpty, true);
      expect(jobs.first.id, startsWith('#'));
    });

    test('createJob and updateJobStatus end-to-end with real Spring Boot Backend', () async {
      final style = JobRepository.getStyleForJobType('ซ่อมบำรุง');

      // 1. Create a new Job
      final newJob = Job(
        id: '',
        title: 'ทดสอบ Integration Test อัตโนมัติ',
        client: 'บริษัท ทดสอบ จำกัด',
        time: '11:00',
        date: 'วันนี้',
        location: 'สำนักงานใหญ่ กรุงเทพฯ',
        status: 'รอดำเนินการ',
        statusColor: const Color(0xFFEF4444),
        statusBgColor: const Color(0xFFFEE2E2),
        icon: style['icon'] as IconData,
        iconColor: style['iconColor'] as Color,
        iconBgColor: style['iconBgColor'] as Color,
        priority: 'Medium',
        jobType: 'ซ่อมบำรุง',
        description: 'ทดสอบการเชื่อมต่อ API End-to-End',
        technician: 'สมชาย ใจดี',
      );

      final created = await JobRepository.instance.createJob(newJob);
      expect(created.id, startsWith('#'));
      expect(created.title, 'ทดสอบ Integration Test อัตโนมัติ');
      expect(created.status, 'รอดำเนินการ');
      expect(created.version, 0);

      // 2. Update status: PENDING -> IN_PROGRESS
      final startSuccess = await JobRepository.instance.updateJobStatus(
        created.id,
        'กำลังดำเนินการ',
        note: 'กำลังเริ่มทดสอบ',
      );
      expect(startSuccess, true);

      final updatedJob1 = JobRepository.instance.getJobById(created.id);
      expect(updatedJob1?.status, 'กำลังดำเนินการ');
      expect(updatedJob1?.version, 1);

      // 3. Update status: IN_PROGRESS -> COMPLETED
      final completeSuccess = await JobRepository.instance.updateJobStatus(
        created.id,
        'เสร็จสิ้น',
        note: 'เสร็จสิ้นเรียบร้อย',
      );
      expect(completeSuccess, true);

      final updatedJob2 = JobRepository.instance.getJobById(created.id);
      expect(updatedJob2?.status, 'เสร็จสิ้น');
      expect(updatedJob2?.version, 2);

      // 4. Invalid transition: COMPLETED -> IN_PROGRESS should be rejected (400 or 409)
      final invalidTransition = await JobRepository.instance.updateJobStatus(
        created.id,
        'กำลังดำเนินการ',
      );
      expect(invalidTransition, false);
      expect(JobRepository.instance.errorMessage, isNotNull);
    });
  });
}
