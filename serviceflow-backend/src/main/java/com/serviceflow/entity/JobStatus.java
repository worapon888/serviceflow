package com.serviceflow.entity;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

import java.util.Arrays;
import java.util.Collections;
import java.util.EnumSet;
import java.util.Set;

/**
 * Status of a field service job with Thai labels and state machine rules.
 */
public enum JobStatus {
    PENDING("รอดำเนินการ"),
    IN_PROGRESS("กำลังดำเนินการ"),
    COMPLETED("เสร็จสิ้น"),
    CANCELLED("ยกเลิก");

    private final String thaiLabel;

    JobStatus(String thaiLabel) {
        this.thaiLabel = thaiLabel;
    }

    public String getThaiLabel() {
        return thaiLabel;
    }

    @JsonValue
    public String getCode() {
        return this.name();
    }

    /**
     * Checks if transitioning from this status to target status is valid.
     */
    public boolean canTransitionTo(JobStatus target) {
        if (this == target) {
            return true;
        }

        return switch (this) {
            case PENDING -> target == IN_PROGRESS || target == CANCELLED;
            case IN_PROGRESS -> target == COMPLETED || target == CANCELLED;
            case COMPLETED, CANCELLED -> false;
        };
    }

    /**
     * Checks if this status is a terminal state.
     */
    public boolean isTerminal() {
        return this == COMPLETED || this == CANCELLED;
    }

    public Set<JobStatus> getAllowedNextStatuses() {
        return switch (this) {
            case PENDING -> EnumSet.of(IN_PROGRESS, CANCELLED);
            case IN_PROGRESS -> EnumSet.of(COMPLETED, CANCELLED);
            case COMPLETED, CANCELLED -> Collections.emptySet();
        };
    }

    @JsonCreator
    public static JobStatus fromValue(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        String clean = value.trim();
        for (JobStatus status : JobStatus.values()) {
            if (status.name().equalsIgnoreCase(clean)
                    || status.name().replace("_", "").equalsIgnoreCase(clean.replace("_", ""))
                    || status.thaiLabel.equals(clean)) {
                return status;
            }
        }
        // Handle common variations
        if (clean.equalsIgnoreCase("inProgress")) {
            return IN_PROGRESS;
        }
        throw new IllegalArgumentException("Unknown JobStatus: " + value + ". Allowed: " + Arrays.toString(values()));
    }
}
