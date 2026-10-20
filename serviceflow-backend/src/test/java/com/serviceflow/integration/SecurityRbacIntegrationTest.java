package com.serviceflow.integration;

import com.serviceflow.dto.request.AssignTechnicianRequest;
import com.serviceflow.dto.request.CreateJobRequest;
import com.serviceflow.dto.request.LoginRequest;
import com.serviceflow.dto.request.UpdateJobStatusRequest;
import com.serviceflow.dto.response.ApiResponse;
import com.serviceflow.dto.response.AuthResponse;
import com.serviceflow.dto.response.ErrorResponse;
import com.serviceflow.dto.response.JobResponse;
import com.serviceflow.dto.response.PageResponse;
import com.serviceflow.entity.JobEntity;
import com.serviceflow.entity.JobStatus;
import com.serviceflow.entity.UserEntity;
import com.serviceflow.repository.JobRepository;
import com.serviceflow.repository.UserRepository;
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
class SecurityRbacIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private JobRepository jobRepository;

    @Autowired
    private UserRepository userRepository;

    private String baseUrl;
    private String authUrl;

    private HttpHeaders adminHeaders;
    private HttpHeaders dispatcherHeaders;
    private HttpHeaders technician1Headers;
    private HttpHeaders technician2Headers;

    private UserEntity tech1User;
    private UserEntity tech2User;

    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private HttpHeaders loginAndGetHeaders(String username, String password) {
        LoginRequest req = new LoginRequest(username, password);
        ResponseEntity<ApiResponse<AuthResponse>> res = restTemplate.exchange(
                authUrl + "/login",
                HttpMethod.POST,
                new HttpEntity<>(req),
                new ParameterizedTypeReference<>() {}
        );
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        String token = res.getBody().getData().getAccessToken();
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        return headers;
    }

    @BeforeEach
    void setUp() {
        baseUrl = "http://localhost:" + port + "/api/v1/jobs";
        authUrl = "http://localhost:" + port + "/api/v1/auth";
        restTemplate.getRestTemplate().setRequestFactory(new HttpComponentsClientHttpRequestFactory());

        jobRepository.deleteAll();

        adminHeaders = loginAndGetHeaders("admin", "Admin@123456");
        dispatcherHeaders = loginAndGetHeaders("dispatcher", "Dispatcher@123");
        technician1Headers = loginAndGetHeaders("technician", "Technician@123");
        technician2Headers = loginAndGetHeaders("technician2", "Technician@123");

        tech1User = userRepository.findByUsername("technician").orElseThrow();
        tech2User = userRepository.findByUsername("technician2").orElseThrow();
    }

    @Test
    @DisplayName("6. ADMIN: Can view all jobs and create new jobs")
    void testAdmin_CanViewAllJobsAndCreate() {
        // Seed job for tech1 and job for tech2
        JobEntity j1 = new JobEntity("#00010", "Job Tech 1", "Client A", "วันนี้", "09:00", "Loc A",
                JobStatus.PENDING, "High", "ซ่อมบำรุง", "", tech1User.getFullName(), "");
        j1.setAssignedTechnician(tech1User);
        jobRepository.save(j1);

        JobEntity j2 = new JobEntity("#00011", "Job Tech 2", "Client B", "วันนี้", "10:00", "Loc B",
                JobStatus.PENDING, "Medium", "ติดตั้ง", "", tech2User.getFullName(), "");
        j2.setAssignedTechnician(tech2User);
        jobRepository.save(j2);

        // Admin queries job list
        ResponseEntity<ApiResponse<PageResponse<JobResponse>>> response = restTemplate.exchange(
                baseUrl,
                HttpMethod.GET,
                new HttpEntity<>(adminHeaders),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getData().getTotalElements()).isEqualTo(2);

        // Admin creates job
        CreateJobRequest createReq = new CreateJobRequest();
        createReq.setTitle("Admin Created Job");
        createReq.setClient("Client C");
        createReq.setAppointmentDate("วันนี้");
        createReq.setAppointmentTime("14:00");
        createReq.setLocation("Loc C");
        createReq.setAssignedTechnicianId(tech1User.getId());

        ResponseEntity<ApiResponse<JobResponse>> createRes = restTemplate.exchange(
                baseUrl,
                HttpMethod.POST,
                new HttpEntity<>(createReq, adminHeaders),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(createRes.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(createRes.getBody().getData().getAssignedTechnicianId()).isEqualTo(tech1User.getId());
    }

    @Test
    @DisplayName("7. DISPATCHER: Can create jobs and assign to technicians")
    void testDispatcher_CreateAndAssignJob() {
        // Dispatcher creates job
        CreateJobRequest createReq = new CreateJobRequest();
        createReq.setTitle("Dispatcher Job");
        createReq.setClient("Client D");
        createReq.setAppointmentDate("วันนี้");
        createReq.setAppointmentTime("11:00");
        createReq.setLocation("Loc D");
        createReq.setAssignedTechnicianId(tech1User.getId());

        ResponseEntity<ApiResponse<JobResponse>> createRes = restTemplate.exchange(
                baseUrl,
                HttpMethod.POST,
                new HttpEntity<>(createReq, dispatcherHeaders),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(createRes.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        String jobId = createRes.getBody().getData().getId();
        assertThat(createRes.getBody().getData().getTechnician()).isEqualTo("สมชาย ใจดี");

        // Dispatcher re-assigns job to technician 2
        AssignTechnicianRequest assignReq = new AssignTechnicianRequest(tech2User.getId());
        ResponseEntity<ApiResponse<JobResponse>> assignRes = restTemplate.exchange(
                baseUrl + "/" + encode(jobId) + "/assign",
                HttpMethod.PATCH,
                new HttpEntity<>(assignReq, dispatcherHeaders),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(assignRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(assignRes.getBody().getData().getAssignedTechnicianId()).isEqualTo(tech2User.getId());
        assertThat(assignRes.getBody().getData().getTechnician()).isEqualTo("วิชัย เก่งกล้า");
    }

    @Test
    @DisplayName("8. TECHNICIAN: Can view only their assigned jobs in job list")
    void testTechnician_ViewsOnlyAssignedJobs() {
        // Seed 1 job for Tech1 and 1 job for Tech2
        JobEntity j1 = new JobEntity("#00021", "Tech 1 Task", "Client 1", "วันนี้", "09:00", "Loc 1",
                JobStatus.PENDING, "High", "ซ่อมบำรุง", "", tech1User.getFullName(), "");
        j1.setAssignedTechnician(tech1User);
        jobRepository.save(j1);

        JobEntity j2 = new JobEntity("#00022", "Tech 2 Task", "Client 2", "วันนี้", "10:00", "Loc 2",
                JobStatus.PENDING, "Medium", "ติดตั้ง", "", tech2User.getFullName(), "");
        j2.setAssignedTechnician(tech2User);
        jobRepository.save(j2);

        // Tech 1 queries job list
        ResponseEntity<ApiResponse<PageResponse<JobResponse>>> tech1ListRes = restTemplate.exchange(
                baseUrl,
                HttpMethod.GET,
                new HttpEntity<>(technician1Headers),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(tech1ListRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        // Only 1 job returned, and it's Tech 1's job
        assertThat(tech1ListRes.getBody().getData().getContent()).hasSize(1);
        assertThat(tech1ListRes.getBody().getData().getContent().get(0).getId()).isEqualTo("#00021");
    }

    @Test
    @DisplayName("9. TECHNICIAN: Accessing another technician's job details returns 403 Forbidden")
    void testTechnician_AccessOtherTechnicianJob_Returns403() {
        // Seed job for Tech 2
        JobEntity j2 = new JobEntity("#00030", "Tech 2 Exclusive Job", "Client Secret", "วันนี้", "11:00", "Loc Secret",
                JobStatus.PENDING, "High", "ซ่อมบำรุง", "", tech2User.getFullName(), "");
        j2.setAssignedTechnician(tech2User);
        jobRepository.save(j2);

        // Tech 1 attempts to view Tech 2's job by ID
        ResponseEntity<ErrorResponse> response = restTemplate.exchange(
                baseUrl + "/" + encode("#00030"),
                HttpMethod.GET,
                new HttpEntity<>(technician1Headers),
                ErrorResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getStatus()).isEqualTo(403);
    }

    @Test
    @DisplayName("9b. TECHNICIAN: Cannot create jobs (returns 403 Forbidden)")
    void testTechnician_CannotCreateJob_Returns403() {
        CreateJobRequest createReq = new CreateJobRequest();
        createReq.setTitle("Tech Attempting Creation");
        createReq.setClient("Client Unauthorized");
        createReq.setAppointmentDate("วันนี้");
        createReq.setAppointmentTime("15:00");
        createReq.setLocation("Loc");

        ResponseEntity<ErrorResponse> response = restTemplate.exchange(
                baseUrl,
                HttpMethod.POST,
                new HttpEntity<>(createReq, technician1Headers),
                ErrorResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    @DisplayName("9c. TECHNICIAN: Cannot update status of another technician's job (returns 403 Forbidden)")
    void testTechnician_CannotUpdateOtherTechnicianJobStatus_Returns403() {
        // Job assigned to Tech 2
        JobEntity j2 = new JobEntity("#00035", "Tech 2 Job", "Client 2", "วันนี้", "13:00", "Loc",
                JobStatus.PENDING, "Low", "ติดตั้ง", "", tech2User.getFullName(), "");
        j2.setAssignedTechnician(tech2User);
        jobRepository.save(j2);

        // Tech 1 attempts to update Tech 2's job
        UpdateJobStatusRequest updateReq = new UpdateJobStatusRequest(JobStatus.IN_PROGRESS, "Tech 1 tampering");
        ResponseEntity<ErrorResponse> response = restTemplate.exchange(
                baseUrl + "/" + encode("#00035") + "/status",
                HttpMethod.PATCH,
                new HttpEntity<>(updateReq, technician1Headers),
                ErrorResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    @DisplayName("10. Status Transition: Technician can update their own job status following allowed transitions")
    void testTechnician_UpdateOwnJobStatus_Success() {
        // Job assigned to Tech 1
        JobEntity j1 = new JobEntity("#00040", "Tech 1 Job", "Client 1", "วันนี้", "14:00", "Loc",
                JobStatus.PENDING, "Medium", "ซ่อมบำรุง", "", tech1User.getFullName(), "");
        j1.setAssignedTechnician(tech1User);
        jobRepository.save(j1);

        // Tech 1 transitions PENDING -> IN_PROGRESS
        UpdateJobStatusRequest startReq = new UpdateJobStatusRequest(JobStatus.IN_PROGRESS, "ช่างเริ่มดำเนินการ");
        ResponseEntity<ApiResponse<JobResponse>> startRes = restTemplate.exchange(
                baseUrl + "/" + encode("#00040") + "/status",
                HttpMethod.PATCH,
                new HttpEntity<>(startReq, technician1Headers),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(startRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(startRes.getBody().getData().getStatus()).isEqualTo(JobStatus.IN_PROGRESS);

        // Tech 1 transitions IN_PROGRESS -> COMPLETED
        UpdateJobStatusRequest completeReq = new UpdateJobStatusRequest(JobStatus.COMPLETED, "ช่างทำงานเสร็จแล้ว");
        ResponseEntity<ApiResponse<JobResponse>> completeRes = restTemplate.exchange(
                baseUrl + "/" + encode("#00040") + "/status",
                HttpMethod.PATCH,
                new HttpEntity<>(completeReq, technician1Headers),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(completeRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(completeRes.getBody().getData().getStatus()).isEqualTo(JobStatus.COMPLETED);
    }

    @Test
    @DisplayName("11. Concurrent Update: Stale version in update status triggers 409 Conflict")
    void testOptimisticLocking_ConcurrentConflict() {
        JobEntity j = new JobEntity("#00050", "Concurrent Job", "Client Concurrency", "วันนี้", "16:00", "Loc",
                JobStatus.PENDING, "High", "ซ่อมบำรุง", "", tech1User.getFullName(), "");
        j.setAssignedTechnician(tech1User);
        jobRepository.save(j);

        // Send stale version = 999
        UpdateJobStatusRequest staleReq = new UpdateJobStatusRequest(JobStatus.IN_PROGRESS, "note", 999L);
        ResponseEntity<String> response = restTemplate.exchange(
                baseUrl + "/" + encode("#00050") + "/status",
                HttpMethod.PATCH,
                new HttpEntity<>(staleReq, technician1Headers),
                String.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(response.getBody()).containsIgnoringCase("conflict");
    }

    @Test
    @DisplayName("12. Data Preservation: Existing technician relationship is preserved and accurate")
    void testDataPreservation_ExistingJobsPreserved() {
        JobEntity job = new JobEntity("#00060", "Legacy Preserved Job", "Old Client", "วันนี้", "08:00", "Old Loc",
                JobStatus.PENDING, "Low", "ตรวจสอบ", "Old Desc", "สมชาย ใจดี", "");
        job.setAssignedTechnician(tech1User);
        jobRepository.save(job);

        ResponseEntity<ApiResponse<JobResponse>> response = restTemplate.exchange(
                baseUrl + "/" + encode("#00060"),
                HttpMethod.GET,
                new HttpEntity<>(adminHeaders),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        JobResponse data = response.getBody().getData();
        assertThat(data.getId()).isEqualTo("#00060");
        assertThat(data.getTitle()).isEqualTo("Legacy Preserved Job");
        assertThat(data.getTechnician()).isEqualTo("สมชาย ใจดี");
        assertThat(data.getAssignedTechnicianId()).isEqualTo(tech1User.getId());
    }

    @Test
    @DisplayName("13. SECURITY REGRESSION: Unauthenticated access to /api/v1/jobs returns 401 Unauthorized")
    void testUnauthenticated_GetJobs_Returns401() {
        ResponseEntity<String> response = restTemplate.exchange(
                baseUrl,
                HttpMethod.GET,
                HttpEntity.EMPTY,
                String.class
        );
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    @DisplayName("14. SECURITY REGRESSION: Unauthenticated access to /api/v1/jobs/{id}/assign returns 401 Unauthorized")
    void testUnauthenticated_AssignJob_Returns401() {
        AssignTechnicianRequest assignReq = new AssignTechnicianRequest(tech1User.getId());
        ResponseEntity<String> response = restTemplate.exchange(
                baseUrl + "/" + encode("#00060") + "/assign",
                HttpMethod.PATCH,
                new HttpEntity<>(assignReq),
                String.class
        );
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }
}

