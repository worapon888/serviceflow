package com.serviceflow.dto.request;

import com.serviceflow.entity.JobStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

@Schema(description = "Request payload for updating a job's status")
public class UpdateJobStatusRequest {

    @Schema(description = "Target status (e.g. IN_PROGRESS, COMPLETED, CANCELLED or Thai labels)", example = "IN_PROGRESS", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull(message = "Target status is required")
    private JobStatus status;

    @Schema(description = "Optional status transition note", example = "เริ่มลงมือตรวจสอบอาการหน้างาน")
    @Size(max = 1000, message = "Note must not exceed 1000 characters")
    private String note = "";

    @Schema(description = "Current version for Optimistic Lock verification (optional)", example = "0")
    private Long version;

    public UpdateJobStatusRequest() {
    }

    public UpdateJobStatusRequest(JobStatus status, String note) {
        this.status = status;
        this.note = note != null ? note : "";
    }

    public UpdateJobStatusRequest(JobStatus status, String note, Long version) {
        this.status = status;
        this.note = note != null ? note : "";
        this.version = version;
    }

    public JobStatus getStatus() {
        return status;
    }

    public void setStatus(JobStatus status) {
        this.status = status;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }

    public Long getVersion() {
        return version;
    }

    public void setVersion(Long version) {
        this.version = version;
    }
}
