package com.serviceflow.entity;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

import java.util.Arrays;

public enum JobPriority {
    LOW("Low"),
    MEDIUM("Medium"),
    HIGH("High");

    private final String value;

    JobPriority(String value) {
        this.value = value;
    }

    @JsonValue
    public String getValue() {
        return value;
    }

    @JsonCreator
    public static JobPriority fromValue(String value) {
        if (value == null || value.trim().isEmpty()) {
            return MEDIUM;
        }
        for (JobPriority p : JobPriority.values()) {
            if (p.name().equalsIgnoreCase(value.trim()) || p.value.equalsIgnoreCase(value.trim())) {
                return p;
            }
        }
        throw new IllegalArgumentException("Unknown JobPriority: " + value + ". Allowed: " + Arrays.toString(values()));
    }
}
