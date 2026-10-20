package com.serviceflow.controller;

import com.serviceflow.dto.request.CreateJobRequest;
import com.serviceflow.dto.request.UpdateJobStatusRequest;
import com.serviceflow.dto.response.ApiResponse;
import com.serviceflow.dto.response.JobResponse;
import com.serviceflow.dto.response.JobStatisticsResponse;
import com.serviceflow.dto.response.PageResponse;
import com.serviceflow.entity.JobStatus;
import com.serviceflow.service.JobService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;

import com.serviceflow.dto.request.AssignTechnicianRequest;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.security.access.prepost.PreAuthorize;

@RestController
@RequestMapping("/api/v1/jobs")
@Tag(name = "Job Management", description = "Endpoints for managing Field Service jobs, status workflows, and statistics")
@SecurityRequirement(name = "bearerAuth")
public class JobController {

    private final JobService jobService;

    public JobController(JobService jobService) {
        this.jobService = jobService;
    }

    @GetMapping
    @Operation(summary = "Get paginated job list", description = "Retrieve jobs with pagination, filtering by status, and search query on ID, title, or client")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Successfully retrieved job list")
    })
    public ResponseEntity<ApiResponse<PageResponse<JobResponse>>> getJobs(
            @Parameter(description = "Page number (0-based)") @RequestParam(defaultValue = "0") int page,
            @Parameter(description = "Number of items per page (1-100)") @RequestParam(defaultValue = "10") int size,
            @Parameter(description = "Field to sort by") @RequestParam(defaultValue = "createdAt") String sortBy,
            @Parameter(description = "Sort direction (asc or desc)") @RequestParam(defaultValue = "desc") String sortDir,
            @Parameter(description = "Filter by status (PENDING, IN_PROGRESS, COMPLETED, CANCELLED)") @RequestParam(required = false) JobStatus status,
            @Parameter(description = "Search keyword for Job ID, title, or client") @RequestParam(required = false) String search
    ) {
        PageResponse<JobResponse> result = jobService.getJobs(page, size, sortBy, sortDir, status, search);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    @GetMapping("/statistics")
    @Operation(summary = "Get job counts and statistics", description = "Retrieve total jobs count and broken down counts by status (Pending, In Progress, Completed, Cancelled)")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Statistics retrieved successfully")
    })
    public ResponseEntity<ApiResponse<JobStatisticsResponse>> getStatistics() {
        JobStatisticsResponse stats = jobService.getStatistics();
        return ResponseEntity.ok(ApiResponse.ok(stats));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get job details by ID", description = "Retrieve detailed information of a specific job by its ID (e.g. #00028)")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Job found and returned"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Job with specified ID not found")
    })
    public ResponseEntity<ApiResponse<JobResponse>> getJobById(
            @Parameter(description = "Job ID (e.g. #00028)", required = true) @PathVariable String id
    ) {
        JobResponse job = jobService.getJobById(normalizeId(id));
        return ResponseEntity.ok(ApiResponse.ok(job));
    }

    @PostMapping
    @Operation(summary = "Create a new field service job", description = "Creates a new job with default PENDING status and atomic sequential ID generation")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Job created successfully"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Validation error in request payload"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "409", description = "Job ID conflict")
    })
    // Permitted for mobile field service creation
    public ResponseEntity<ApiResponse<JobResponse>> createJob(
            @Valid @RequestBody CreateJobRequest request
    ) {
        JobResponse createdJob = jobService.createJob(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(createdJob.getId())
                .toUri();

        return ResponseEntity.created(location)
                .body(ApiResponse.created("Job created successfully", createdJob));
    }

    @PatchMapping("/{id}/assign")
    @PreAuthorize("hasAnyRole('ADMIN', 'DISPATCHER')")
    @Operation(summary = "Assign technician to job", description = "Assign an active technician to a specific job (Dispatchers and Admins only)")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Technician assigned successfully"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Invalid request payload or user is not a technician"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Forbidden - Technicians cannot assign jobs"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Job or technician not found")
    })
    public ResponseEntity<ApiResponse<JobResponse>> assignTechnician(
            @Parameter(description = "Job ID", required = true) @PathVariable String id,
            @Valid @RequestBody AssignTechnicianRequest request
    ) {
        JobResponse updatedJob = jobService.assignTechnician(normalizeId(id), request.getTechnicianId());
        return ResponseEntity.ok(ApiResponse.ok("Technician assigned successfully", updatedJob));
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Update job status", description = "Perform state machine transition for a job with validation, status note, and optimistic locking")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Job status updated successfully"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Invalid request payload or malformed status"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Forbidden - Technicians cannot update others' jobs"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Job not found"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "409", description = "Illegal status transition or concurrent update conflict")
    })
    public ResponseEntity<ApiResponse<JobResponse>> updateJobStatus(
            @Parameter(description = "Job ID", required = true) @PathVariable String id,
            @Valid @RequestBody UpdateJobStatusRequest request
    ) {
        JobResponse updatedJob = jobService.updateJobStatus(normalizeId(id), request);
        return ResponseEntity.ok(ApiResponse.ok("Job status updated successfully", updatedJob));
    }

    private String normalizeId(String id) {
        if (id == null) {
            return null;
        }
        try {
            return java.net.URLDecoder.decode(id, java.nio.charset.StandardCharsets.UTF_8);
        } catch (Exception e) {
            return id;
        }
    }
}
