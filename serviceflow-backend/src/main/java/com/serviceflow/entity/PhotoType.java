package com.serviceflow.entity;

public enum PhotoType {
    BEFORE("ก่อนดำเนินการ"),
    AFTER("หลังดำเนินการ");

    private final String description;

    PhotoType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }

    public static PhotoType fromString(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("photoType is required and cannot be blank");
        }
        String trimmed = value.trim().toUpperCase();
        if (trimmed.equals("BEFORE") || trimmed.contains("ก่อน")) {
            return BEFORE;
        }
        if (trimmed.equals("AFTER") || trimmed.contains("หลัง")) {
            return AFTER;
        }
        try {
            return PhotoType.valueOf(trimmed);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid photoType: '" + value + "'. Must be BEFORE or AFTER");
        }
    }
}
