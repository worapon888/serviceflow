package com.serviceflow.integration;

import com.serviceflow.dto.request.CreateJobRequest;
import com.serviceflow.dto.request.LoginRequest;
import com.serviceflow.dto.request.UpdateJobStatusRequest;
import com.serviceflow.dto.response.ApiResponse;
import com.serviceflow.dto.response.AuthResponse;
import com.serviceflow.dto.response.JobResponse;
import com.serviceflow.dto.response.JobStatisticsResponse;
import com.serviceflow.dto.response.PageResponse;
import com.serviceflow.entity.JobEntity;
import com.serviceflow.entity.JobStatus;
import com.serviceflow.repository.JobRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;
import org.springframework.test.context.ActiveProfiles;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class JobIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private JobRepository jobRepository;

    private String baseUrl;
    private HttpHeaders adminHeaders;

    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    @BeforeEach
    void setUp() {
        baseUrl = "http://localhost:" + port + "/api/v1/jobs";
        restTemplate.getRestTemplate().setRequestFactory(new HttpComponentsClientHttpRequestFactory());
        jobRepository.deleteAll();

        // Login as ADMIN to get Bearer token for integration tests
        LoginRequest loginReq = new LoginRequest("admin", "Admin@123456");
        ResponseEntity<ApiResponse<AuthResponse>> loginRes = restTemplate.exchange(
                "http://localhost:" + port + "/api/v1/auth/login",
                HttpMethod.POST,
                new HttpEntity<>(loginReq),
                new ParameterizedTypeReference<>() {}
        );
        assertThat(loginRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(loginRes.getBody()).isNotNull();
        String adminToken = loginRes.getBody().getData().getAccessToken();

        adminHeaders = new HttpHeaders();
        adminHeaders.setBearerAuth(adminToken);
    }

    @Test
    @DisplayName("E2E: Full Job Lifecycle — Create, Query, Transition to In Progress, Complete, and Verify Stats")
    void testFullJobLifecycle() {
        // 1. Create Job
        CreateJobRequest createReq = new CreateJobRequest();
        createReq.setTitle("ตรวจระบบท่อน้ำดี");
        createReq.setClient("โรงแรม สยามพลาซ่า");
        createReq.setAppointmentDate("วันนี้");
        createReq.setAppointmentTime("13:00");
        createReq.setLocation("55 ถนนรัชดาภิเษก ดินแดง กรุงเทพฯ");
        createReq.setPriority("High");
        createReq.setJobType("ซ่อมบำรุง");

        ResponseEntity<ApiResponse<JobResponse>> createRes = restTemplate.exchange(
                baseUrl,
                HttpMethod.POST,
                new HttpEntity<>(createReq, adminHeaders),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(createRes.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(createRes.getBody()).isNotNull();
        assertThat(createRes.getBody().isSuccess()).isTrue();

        JobResponse createdJob = createRes.getBody().getData();
        assertThat(createdJob.getId()).startsWith("#");
        assertThat(createdJob.getStatus()).isEqualTo(JobStatus.PENDING);
        assertThat(createdJob.getStatusLabel()).isEqualTo("รอดำเนินการ");
        String jobId = createdJob.getId();

        // 2. Query Job By ID
        ResponseEntity<ApiResponse<JobResponse>> getRes = restTemplate.exchange(
                baseUrl + "/" + encode(jobId),
                HttpMethod.GET,
                new HttpEntity<>(adminHeaders),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(getRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(getRes.getBody()).isNotNull();
        assertThat(getRes.getBody().getData().getTitle()).isEqualTo("ตรวจระบบท่อน้ำดี");

        // 3. Transition: PENDING -> IN_PROGRESS
        UpdateJobStatusRequest startReq = new UpdateJobStatusRequest(JobStatus.IN_PROGRESS, "ช่างเดินทางถึงหน้างานแล้ว");
        ResponseEntity<ApiResponse<JobResponse>> startRes = restTemplate.exchange(
                baseUrl + "/" + encode(jobId) + "/status",
                HttpMethod.PATCH,
                new HttpEntity<>(startReq, adminHeaders),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(startRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(startRes.getBody()).isNotNull();
        assertThat(startRes.getBody().getData().getStatus()).isEqualTo(JobStatus.IN_PROGRESS);
        assertThat(startRes.getBody().getData().getStatusNote()).isEqualTo("ช่างเดินทางถึงหน้างานแล้ว");

        // 4. Transition: IN_PROGRESS -> COMPLETED
        UpdateJobStatusRequest completeReq = new UpdateJobStatusRequest(JobStatus.COMPLETED, "ซ่อมท่อเสร็จเรียบร้อยและทดสอบแรงดันน้ำผ่าน");
        ResponseEntity<ApiResponse<JobResponse>> completeRes = restTemplate.exchange(
                baseUrl + "/" + encode(jobId) + "/status",
                HttpMethod.PATCH,
                new HttpEntity<>(completeReq, adminHeaders),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(completeRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(completeRes.getBody().getData().getStatus()).isEqualTo(JobStatus.COMPLETED);
        assertThat(completeRes.getBody().getData().getStatusLabel()).isEqualTo("เสร็จสิ้น");

        // 5. Illegal transition from Terminal State: COMPLETED -> PENDING should fail with 409 CONFLICT
        UpdateJobStatusRequest illegalReq = new UpdateJobStatusRequest(JobStatus.PENDING, "พยายามย้อนสถานะ");
        ResponseEntity<String> illegalRes = restTemplate.exchange(
                baseUrl + "/" + encode(jobId) + "/status",
                HttpMethod.PATCH,
                new HttpEntity<>(illegalReq, adminHeaders),
                String.class
        );

        assertThat(illegalRes.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);

        // 6. Verify Statistics
        ResponseEntity<ApiResponse<JobStatisticsResponse>> statsRes = restTemplate.exchange(
                baseUrl + "/statistics",
                HttpMethod.GET,
                new HttpEntity<>(adminHeaders),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(statsRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(statsRes.getBody()).isNotNull();
        JobStatisticsResponse stats = statsRes.getBody().getData();
        assertThat(stats.getTotal()).isEqualTo(1);
        assertThat(stats.getCompleted()).isEqualTo(1);
        assertThat(stats.getPending()).isEqualTo(0);
        assertThat(stats.getInProgress()).isEqualTo(0);
    }

    @Test
    @DisplayName("Search & Filter: Retrieve jobs with status filter and keyword search")
    void testSearchAndFilter() {
        // Seed 2 jobs
        JobEntity job1 = new JobEntity("#00001", "ตรวจล้างแอร์ห้องประชุม", "บริษัท เอสซีจี จำกัด",
                "วันนี้", "09:00", "บางซื่อ", JobStatus.PENDING, "High", "ซ่อมบำรุง", "", "สมชาย ใจดี", "");
        JobEntity job2 = new JobEntity("#00002", "ติดตั้งแอร์ใหม่", "บริษัท ปตท. จำกัด",
                "วันนี้", "14:00", "จตุจักร", JobStatus.COMPLETED, "Medium", "ติดตั้ง", "", "สมชาย ใจดี", "");

        jobRepository.save(job1);
        jobRepository.save(job2);

        // Search for "ปตท"
        ResponseEntity<ApiResponse<PageResponse<JobResponse>>> searchRes = restTemplate.exchange(
                baseUrl + "?search=ปตท",
                HttpMethod.GET,
                new HttpEntity<>(adminHeaders),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(searchRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(searchRes.getBody()).isNotNull();
        assertThat(searchRes.getBody().getData().getContent()).hasSize(1);
        assertThat(searchRes.getBody().getData().getContent().get(0).getId()).isEqualTo("#00002");

        // Filter by status=PENDING
        ResponseEntity<ApiResponse<PageResponse<JobResponse>>> filterRes = restTemplate.exchange(
                baseUrl + "?status=PENDING",
                HttpMethod.GET,
                new HttpEntity<>(adminHeaders),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(filterRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(filterRes.getBody()).isNotNull();
        assertThat(filterRes.getBody().getData().getContent()).hasSize(1);
        assertThat(filterRes.getBody().getData().getContent().get(0).getId()).isEqualTo("#00001");
    }

    @Test
    @DisplayName("Optimistic Locking Conflict: Stale version in request triggers 409 Conflict")
    void testOptimisticLockingFailure() {
        JobEntity job = new JobEntity("#00099", "งานทดสอบ Concurrency", "ทดสอบ จำกัด",
                "วันนี้", "10:00", "กรุงเทพฯ", JobStatus.PENDING, "Medium", "ซ่อมบำรุง", "", "สมชาย ใจดี", "");
        job = jobRepository.save(job);

        // Request with stale version (e.g. version = 999 while current is 0)
        UpdateJobStatusRequest conflictReq = new UpdateJobStatusRequest(JobStatus.IN_PROGRESS, "note", 999L);
        ResponseEntity<String> conflictRes = restTemplate.exchange(
                baseUrl + "/" + encode("#00099") + "/status",
                HttpMethod.PATCH,
                new HttpEntity<>(conflictReq, adminHeaders),
                String.class
        );

        assertThat(conflictRes.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(conflictRes.getBody()).containsIgnoringCase("conflict");
    }
}
