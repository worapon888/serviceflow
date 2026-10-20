package com.serviceflow.exception;

public class JobNotFoundException extends RuntimeException {

    private final String jobId;

    public JobNotFoundException(String jobId) {
        super(String.format("Job with ID '%s' was not found", jobId));
        this.jobId = jobId;
    }

    public String getJobId() {
        return jobId;
    }
}
