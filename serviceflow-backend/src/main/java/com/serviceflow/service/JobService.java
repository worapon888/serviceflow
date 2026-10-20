package com.serviceflow.service;

import com.serviceflow.dto.request.CreateJobRequest;
import com.serviceflow.dto.request.UpdateJobStatusRequest;
import com.serviceflow.dto.response.JobResponse;
import com.serviceflow.dto.response.JobStatisticsResponse;
import com.serviceflow.dto.response.PageResponse;
import com.serviceflow.entity.JobStatus;

public interface JobService {

    PageResponse<JobResponse> getJobs(int page, int size, String sortBy, String sortDir, JobStatus status, String search);

    JobResponse getJobById(String id);

    JobResponse createJob(CreateJobRequest request);

    JobResponse updateJobStatus(String id, UpdateJobStatusRequest request);

    JobResponse assignTechnician(String id, Long technicianId);

    JobStatisticsResponse getStatistics();
}
