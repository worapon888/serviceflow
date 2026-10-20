package com.serviceflow.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "jobs", indexes = {
        @Index(name = "idx_jobs_status", columnList = "status"),
        @Index(name = "idx_jobs_client", columnList = "client"),
        @Index(name = "idx_jobs_created_at", columnList = "created_at DESC"),
        @Index(name = "idx_jobs_title", columnList = "title"),
        @Index(name = "idx_jobs_assigned_technician", columnList = "assigned_technician_id")
})
public class JobEntity {

    @Id
    @Column(name = "id", length = 32, nullable = false)
    private String id;

    @Column(name = "title", length = 255, nullable = false)
    private String title;

    @Column(name = "client", length = 255, nullable = false)
    private String client;

    @Column(name = "appointment_date", length = 100, nullable = false)
    private String appointmentDate;

    @Column(name = "appointment_time", length = 50, nullable = false)
    private String appointmentTime;

    @Column(name = "location", length = 500, nullable = false)
    private String location;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 50, nullable = false)
    private JobStatus status = JobStatus.PENDING;

    @Column(name = "priority", length = 50, nullable = false)
    private String priority = "Medium";

    @Column(name = "job_type", length = 100, nullable = false)
    private String jobType = "ซ่อมบำรุง";

    @Column(name = "description", columnDefinition = "TEXT")
    private String description = "";

    @Column(name = "technician", length = 255, nullable = false)
    private String technician = "สมชาย ใจดี";

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_technician_id")
    private UserEntity assignedTechnician;

    @Column(name = "status_note", columnDefinition = "TEXT")
    private String statusNote = "";

    @Version
    @Column(name = "version", nullable = false)
    private Long version = 0L;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @OneToMany(mappedBy = "job", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<JobPhotoEntity> photos = new ArrayList<>();

    public JobEntity() {
    }

    public JobEntity(String id, String title, String client, String appointmentDate, String appointmentTime,
                     String location, JobStatus status, String priority, String jobType, String description,
                     String technician, String statusNote) {
        this.id = id;
        this.title = title;
        this.client = client;
        this.appointmentDate = appointmentDate;
        this.appointmentTime = appointmentTime;
        this.location = location;
        this.status = status != null ? status : JobStatus.PENDING;
        this.priority = priority != null ? priority : "Medium";
        this.jobType = jobType != null ? jobType : "ซ่อมบำรุง";
        this.description = description != null ? description : "";
        this.technician = technician != null ? technician : "สมชาย ใจดี";
        this.statusNote = statusNote != null ? statusNote : "";
    }

    // Getters and Setters

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getClient() {
        return client;
    }

    public void setClient(String client) {
        this.client = client;
    }

    public String getAppointmentDate() {
        return appointmentDate;
    }

    public void setAppointmentDate(String appointmentDate) {
        this.appointmentDate = appointmentDate;
    }

    public String getAppointmentTime() {
        return appointmentTime;
    }

    public void setAppointmentTime(String appointmentTime) {
        this.appointmentTime = appointmentTime;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public JobStatus getStatus() {
        return status;
    }

    public void setStatus(JobStatus status) {
        this.status = status;
    }

    public String getPriority() {
        return priority;
    }

    public void setPriority(String priority) {
        this.priority = priority;
    }

    public String getJobType() {
        return jobType;
    }

    public void setJobType(String jobType) {
        this.jobType = jobType;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getTechnician() {
        return technician;
    }

    public void setTechnician(String technician) {
        this.technician = technician;
    }

    public UserEntity getAssignedTechnician() {
        return assignedTechnician;
    }

    public void setAssignedTechnician(UserEntity assignedTechnician) {
        this.assignedTechnician = assignedTechnician;
        if (assignedTechnician != null && assignedTechnician.getFullName() != null) {
            this.technician = assignedTechnician.getFullName();
        }
    }

    public String getStatusNote() {
        return statusNote;
    }

    public void setStatusNote(String statusNote) {
        this.statusNote = statusNote;
    }

    public Long getVersion() {
        return version;
    }

    public void setVersion(Long version) {
        this.version = version;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public List<JobPhotoEntity> getPhotos() {
        return photos;
    }

    public void setPhotos(List<JobPhotoEntity> photos) {
        this.photos = photos;
    }

    public void addPhoto(JobPhotoEntity photo) {
        photos.add(photo);
        photo.setJob(this);
    }

    public void removePhoto(JobPhotoEntity photo) {
        photos.remove(photo);
        photo.setJob(null);
    }
}
