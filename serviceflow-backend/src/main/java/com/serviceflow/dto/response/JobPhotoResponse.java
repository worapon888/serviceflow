package com.serviceflow.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.OffsetDateTime;

@Schema(description = "Job Photo Details Response DTO")
public class JobPhotoResponse {

    @Schema(description = "Unique Photo ID", example = "photo_1729339200000_a1b2c3d4")
    private String id;

    @Schema(description = "Associated Job ID", example = "#00037")
    private String jobId;

    @Schema(description = "Photo Type (BEFORE / AFTER)", example = "BEFORE")
    private String photoType;

    @Schema(description = "Optional technician notes", example = "สภาพเครื่องก่อนเริ่มซ่อมบำรุง")
    private String note;

    @Schema(description = "Creation timestamp")
    private OffsetDateTime createdAt;

    @Schema(description = "Protected URL endpoint to fetch/stream the image content", example = "/api/v1/jobs/%2300037/photos/photo_1729339200000_a1b2c3d4/content")
    private String url;

    @Schema(description = "Relative storage key in backend storage", example = "#00037/550e8400-e29b-41d4-a716-446655440000.jpg")
    private String storageKey;

    public JobPhotoResponse() {
    }

    public JobPhotoResponse(String id, String jobId, String photoType, String note, OffsetDateTime createdAt, String url, String storageKey) {
        this.id = id;
        this.jobId = jobId;
        this.photoType = photoType;
        this.note = note != null ? note : "";
        this.createdAt = createdAt;
        this.url = url;
        this.storageKey = storageKey;
    }

    // Alias for Flutter compatibility
    @JsonProperty("imagePath")
    public String getImagePath() {
        return url;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getJobId() {
        return jobId;
    }

    public void setJobId(String jobId) {
        this.jobId = jobId;
    }

    public String getPhotoType() {
        return photoType;
    }

    public void setPhotoType(String photoType) {
        this.photoType = photoType;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public String getStorageKey() {
        return storageKey;
    }

    public void setStorageKey(String storageKey) {
        this.storageKey = storageKey;
    }
}
