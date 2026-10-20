package com.serviceflow.exception;

import com.serviceflow.entity.JobStatus;

public class InvalidStatusTransitionException extends RuntimeException {

    private final String jobId;
    private final JobStatus currentStatus;
    private final JobStatus targetStatus;

    public InvalidStatusTransitionException(String jobId, JobStatus currentStatus, JobStatus targetStatus) {
        super(String.format("Cannot transition job '%s' from status '%s' (%s) to '%s' (%s). Allowed next statuses: %s",
                jobId,
                currentStatus.name(),
                currentStatus.getThaiLabel(),
                targetStatus.name(),
                targetStatus.getThaiLabel(),
                currentStatus.getAllowedNextStatuses()));
        this.jobId = jobId;
        this.currentStatus = currentStatus;
        this.targetStatus = targetStatus;
    }

    public String getJobId() {
        return jobId;
    }

    public JobStatus getCurrentStatus() {
        return currentStatus;
    }

    public JobStatus getTargetStatus() {
        return targetStatus;
    }
}
