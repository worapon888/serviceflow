package com.serviceflow.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.serviceflow.dto.request.CreateJobRequest;
import com.serviceflow.dto.request.UpdateJobStatusRequest;
import com.serviceflow.dto.response.JobResponse;
import com.serviceflow.dto.response.JobStatisticsResponse;
import com.serviceflow.dto.response.PageResponse;
import com.serviceflow.entity.JobStatus;
import com.serviceflow.exception.GlobalExceptionHandler;
import com.serviceflow.exception.InvalidStatusTransitionException;
import com.serviceflow.exception.JobNotFoundException;
import com.serviceflow.service.JobService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageImpl;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;

@WebMvcTest(JobController.class)
@AutoConfigureMockMvc(addFilters = false)
@Import(GlobalExceptionHandler.class)
class JobControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private JobService jobService;

    @MockBean
    private com.serviceflow.security.JwtTokenProvider jwtTokenProvider;

    @MockBean
    private com.serviceflow.security.CustomUserDetailsService userDetailsService;

    @Test
    @DisplayName("GET /api/v1/jobs should return 200 and paginated list")
    void testGetJobs_Success() throws Exception {
        JobResponse job = new JobResponse();
        job.setId("#00028");
        job.setTitle("ตรวจล้างแอร์");
        job.setClient("บริษัท ABC จำกัด");
        job.setStatus(JobStatus.PENDING);

        PageResponse<JobResponse> pageResponse = new PageResponse<>(new PageImpl<>(List.of(job)));

        when(jobService.getJobs(0, 10, "createdAt", "desc", null, null))
                .thenReturn(pageResponse);

        mockMvc.perform(get("/api/v1/jobs")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content", hasSize(1)))
                .andExpect(jsonPath("$.data.content[0].id").value("#00028"))
                .andExpect(jsonPath("$.data.content[0].status").value("PENDING"))
                .andExpect(jsonPath("$.data.content[0].statusLabel").value("รอดำเนินการ"));
    }

    @Test
    @DisplayName("GET /api/v1/jobs/{id} should return 200 when job exists")
    void testGetJobById_Found() throws Exception {
        JobResponse job = new JobResponse();
        job.setId("#00028");
        job.setTitle("ตรวจล้างแอร์");
        job.setClient("บริษัท ABC จำกัด");
        job.setStatus(JobStatus.PENDING);

        when(jobService.getJobById("#00028")).thenReturn(job);

        mockMvc.perform(get("/api/v1/jobs/{id}", "#00028")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value("#00028"))
                .andExpect(jsonPath("$.data.title").value("ตรวจล้างแอร์"));
    }

    @Test
    @DisplayName("GET /api/v1/jobs/{id} should return 404 when job not found")
    void testGetJobById_NotFound() throws Exception {
        when(jobService.getJobById("#99999")).thenThrow(new JobNotFoundException("#99999"));

        mockMvc.perform(get("/api/v1/jobs/{id}", "#99999")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.message", containsString("#99999")));
    }

    @Test
    @DisplayName("POST /api/v1/jobs with valid payload should return 201 Created")
    void testCreateJob_Valid_Success() throws Exception {
        CreateJobRequest request = new CreateJobRequest();
        request.setTitle("ติดตั้งระบบ CCTV");
        request.setClient("บริษัท XYZ จำกัด");
        request.setAppointmentDate("วันนี้");
        request.setAppointmentTime("10:00");
        request.setLocation("99 ถนนสาทรใต้ ยานนาวา กรุงเทพฯ");

        JobResponse created = new JobResponse();
        created.setId("#00029");
        created.setTitle("ติดตั้งระบบ CCTV");
        created.setStatus(JobStatus.PENDING);

        when(jobService.createJob(any(CreateJobRequest.class))).thenReturn(created);

        mockMvc.perform(post("/api/v1/jobs")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value("#00029"))
                .andExpect(header().string("Location", anyOf(containsString("/api/v1/jobs/#00029"), containsString("/api/v1/jobs/%2300029"))));
    }

    @Test
    @DisplayName("POST /api/v1/jobs with missing required fields should return 400 Bad Request")
    void testCreateJob_ValidationFailure() throws Exception {
        CreateJobRequest invalidRequest = new CreateJobRequest(); // Missing title, client, location, date, time

        mockMvc.perform(post("/api/v1/jobs")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.errors.title").exists())
                .andExpect(jsonPath("$.errors.client").exists())
                .andExpect(jsonPath("$.errors.location").exists());
    }

    @Test
    @DisplayName("PATCH /api/v1/jobs/{id}/status should return 200 on valid status update")
    void testUpdateJobStatus_Success() throws Exception {
        UpdateJobStatusRequest request = new UpdateJobStatusRequest(JobStatus.IN_PROGRESS, "เริ่มดำเนินการ");

        JobResponse response = new JobResponse();
        response.setId("#00028");
        response.setStatus(JobStatus.IN_PROGRESS);

        when(jobService.updateJobStatus(eq("#00028"), any(UpdateJobStatusRequest.class)))
                .thenReturn(response);

        mockMvc.perform(patch("/api/v1/jobs/{id}/status", "#00028")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("IN_PROGRESS"));
    }

    @Test
    @DisplayName("PATCH /api/v1/jobs/{id}/status should return 409 Conflict on invalid state transition")
    void testUpdateJobStatus_InvalidTransition() throws Exception {
        UpdateJobStatusRequest request = new UpdateJobStatusRequest(JobStatus.COMPLETED, "ข้ามขั้นตอน");

        when(jobService.updateJobStatus(eq("#00028"), any(UpdateJobStatusRequest.class)))
                .thenThrow(new InvalidStatusTransitionException("#00028", JobStatus.PENDING, JobStatus.COMPLETED));

        mockMvc.perform(patch("/api/v1/jobs/{id}/status", "#00028")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.status").value(409))
                .andExpect(jsonPath("$.message", containsString("Cannot transition job")));
    }

    @Test
    @DisplayName("GET /api/v1/jobs/statistics should return 200 with stats breakdown")
    void testGetStatistics() throws Exception {
        JobStatisticsResponse stats = new JobStatisticsResponse(24, 8, 10, 6, 0);

        when(jobService.getStatistics()).thenReturn(stats);

        mockMvc.perform(get("/api/v1/jobs/statistics")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.total").value(24))
                .andExpect(jsonPath("$.data.pending").value(8))
                .andExpect(jsonPath("$.data.inProgress").value(10))
                .andExpect(jsonPath("$.data.completed").value(6))
                .andExpect(jsonPath("$.data.cancelled").value(0))
                // Flutter alias fields
                .andExpect(jsonPath("$.data.totalCount").value(24))
                .andExpect(jsonPath("$.data.pendingCount").value(8));
    }
}
