package com.serviceflow.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;

@Entity
@Table(name = "job_photos", indexes = {
        @Index(name = "idx_job_photos_job_id", columnList = "job_id")
})
public class JobPhotoEntity {

    @Id
    @Column(name = "id", length = 64, nullable = false)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "job_id", nullable = false)
    private JobEntity job;

    @Column(name = "image_path", length = 1000, nullable = false)
    private String imagePath;

    @Column(name = "photo_type", length = 50, nullable = false)
    private String photoType;

    @Column(name = "note", columnDefinition = "TEXT")
    private String note = "";

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    public JobPhotoEntity() {
    }

    public JobPhotoEntity(String id, JobEntity job, String imagePath, String photoType, String note) {
        this.id = id;
        this.job = job;
        this.imagePath = imagePath;
        this.photoType = photoType;
        this.note = note != null ? note : "";
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public JobEntity getJob() {
        return job;
    }

    public void setJob(JobEntity job) {
        this.job = job;
    }

    public String getImagePath() {
        return imagePath;
    }

    public void setImagePath(String imagePath) {
        this.imagePath = imagePath;
    }

    public String getStorageKey() {
        return imagePath;
    }

    public void setStorageKey(String storageKey) {
        this.imagePath = storageKey;
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
}
