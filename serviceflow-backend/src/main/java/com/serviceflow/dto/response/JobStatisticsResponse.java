package com.serviceflow.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Job Counts by Status")
public class JobStatisticsResponse {

    @Schema(description = "Total number of jobs", example = "24")
    private long total;

    @Schema(description = "Jobs in PENDING status (รอดำเนินการ)", example = "8")
    private long pending;

    @Schema(description = "Jobs in IN_PROGRESS status (กำลังดำเนินการ)", example = "10")
    private long inProgress;

    @Schema(description = "Jobs in COMPLETED status (เสร็จสิ้น)", example = "6")
    private long completed;

    @Schema(description = "Jobs in CANCELLED status (ยกเลิก)", example = "0")
    private long cancelled;

    public JobStatisticsResponse() {
    }

    public JobStatisticsResponse(long total, long pending, long inProgress, long completed, long cancelled) {
        this.total = total;
        this.pending = pending;
        this.inProgress = inProgress;
        this.completed = completed;
        this.cancelled = cancelled;
    }

    // Aliases for Flutter JobRepository compatibility
    @JsonProperty("totalCount")
    public long getTotalCount() {
        return total;
    }

    @JsonProperty("pendingCount")
    public long getPendingCount() {
        return pending;
    }

    @JsonProperty("inProgressCount")
    public long getInProgressCount() {
        return inProgress;
    }

    @JsonProperty("completedCount")
    public long getCompletedCount() {
        return completed;
    }

    @JsonProperty("cancelledCount")
    public long getCancelledCount() {
        return cancelled;
    }

    public long getTotal() {
        return total;
    }

    public void setTotal(long total) {
        this.total = total;
    }

    public long getPending() {
        return pending;
    }

    public void setPending(long pending) {
        this.pending = pending;
    }

    public long getInProgress() {
        return inProgress;
    }

    public void setInProgress(long inProgress) {
        this.inProgress = inProgress;
    }

    public long getCompleted() {
        return completed;
    }

    public void setCompleted(long completed) {
        this.completed = completed;
    }

    public long getCancelled() {
        return cancelled;
    }

    public void setCancelled(long cancelled) {
        this.cancelled = cancelled;
    }
}
