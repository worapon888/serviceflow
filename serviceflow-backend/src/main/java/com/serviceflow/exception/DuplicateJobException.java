package com.serviceflow.exception;

public class DuplicateJobException extends RuntimeException {

    private final String jobId;

    public DuplicateJobException(String jobId) {
        super(String.format("Job with ID '%s' already exists", jobId));
        this.jobId = jobId;
    }

    public String getJobId() {
        return jobId;
    }
}
