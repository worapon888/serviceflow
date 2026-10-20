package com.serviceflow.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.serviceflow.entity.JobStatus;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.OffsetDateTime;

@Schema(description = "Job Details Response DTO")
public class JobResponse {

    @Schema(description = "Unique Job ID", example = "#00028")
    private String id;

    @Schema(description = "Job Title", example = "ตรวจล้างแอร์")
    private String title;

    @Schema(description = "Client / Customer Name", example = "บริษัท ABC จำกัด")
    private String client;

    @Schema(description = "Appointment Date", example = "วันนี้")
    private String appointmentDate;

    @Schema(description = "Appointment Time", example = "09:00")
    private String appointmentTime;

    @Schema(description = "Location Address", example = "123 ถนนสุขุมวิท เขตวัฒนา กรุงเทพฯ")
    private String location;

    @Schema(description = "Job Status Code", example = "PENDING")
    private JobStatus status;

    @Schema(description = "Job Status Thai Label", example = "รอดำเนินการ")
    private String statusLabel;

    @Schema(description = "Priority Level", example = "High")
    private String priority;

    @Schema(description = "Job Type", example = "ซ่อมบำรุง")
    private String jobType;

    @Schema(description = "Detailed Description", example = "รายละเอียดการปฏิบัติงาน")
    private String description;

    @Schema(description = "Technician Name", example = "สมชาย ใจดี")
    private String technician;

    @Schema(description = "Assigned Technician User ID", example = "3")
    private Long assignedTechnicianId;

    @Schema(description = "Status Note", example = "")
    private String statusNote;

    @Schema(description = "Record Version for Optimistic Locking", example = "0")
    private Long version;

    @Schema(description = "Record Creation Timestamp")
    private OffsetDateTime createdAt;

    @Schema(description = "Record Last Update Timestamp")
    private OffsetDateTime updatedAt;

    @Schema(description = "Attached Photo Count", example = "0")
    private long photoCount;

    public JobResponse() {
    }

    // Aliases for seamless Flutter model compatibility
    @JsonProperty("date")
    public String getDate() {
        return appointmentDate;
    }

    @JsonProperty("time")
    public String getTime() {
        return appointmentTime;
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
        this.statusLabel = status != null ? status.getThaiLabel() : null;
    }

    public String getStatusLabel() {
        return statusLabel;
    }

    public void setStatusLabel(String statusLabel) {
        this.statusLabel = statusLabel;
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

    public Long getAssignedTechnicianId() {
        return assignedTechnicianId;
    }

    public void setAssignedTechnicianId(Long assignedTechnicianId) {
        this.assignedTechnicianId = assignedTechnicianId;
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

    public long getPhotoCount() {
        return photoCount;
    }

    public void setPhotoCount(long photoCount) {
        this.photoCount = photoCount;
    }
}
