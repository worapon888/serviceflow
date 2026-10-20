package com.serviceflow.entity;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum JobType {
    INSTALLATION("ติดตั้ง"),
    MAINTENANCE("ซ่อมบำรุง"),
    INSPECTION("ตรวจสอบ"),
    OTHER("งานบริการอื่น ๆ");

    private final String label;

    JobType(String label) {
        this.label = label;
    }

    @JsonValue
    public String getLabel() {
        return label;
    }

    @JsonCreator
    public static JobType fromValue(String value) {
        if (value == null || value.trim().isEmpty()) {
            return MAINTENANCE;
        }
        String clean = value.trim();
        for (JobType t : JobType.values()) {
            if (t.label.equalsIgnoreCase(clean) || t.name().equalsIgnoreCase(clean)) {
                return t;
            }
        }
        return OTHER;
    }
}
