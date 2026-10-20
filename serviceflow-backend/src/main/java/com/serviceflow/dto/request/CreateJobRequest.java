package com.serviceflow.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

@Schema(description = "Request payload for creating a new field service job")
public class CreateJobRequest {

    @Schema(description = "Custom Job ID (optional; auto-generated if omitted)", example = "#00029")
    @Pattern(regexp = "^#[0-9]{5}$", message = "Job ID must match pattern '#00000'")
    private String id;

    @Schema(description = "Job title", example = "ตรวจล้างแอร์ห้องประชุม", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank(message = "Job title is required")
    @Size(max = 255, message = "Job title must not exceed 255 characters")
    private String title;

    @Schema(description = "Customer / Client name", example = "บริษัท ABC จำกัด", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank(message = "Customer name is required")
    @Size(max = 255, message = "Customer name must not exceed 255 characters")
    private String client;

    @Schema(description = "Appointment date", example = "วันนี้ หรือ 2026-10-20", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank(message = "Appointment date is required")
    @Size(max = 100, message = "Appointment date must not exceed 100 characters")
    private String appointmentDate;

    @Schema(description = "Appointment time", example = "09:30", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank(message = "Appointment time is required")
    @Size(max = 50, message = "Appointment time must not exceed 50 characters")
    private String appointmentTime;

    @Schema(description = "Service location / Address", example = "123 ถนนสุขุมวิท เขตวัฒนา กรุงเทพฯ", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank(message = "Location is required")
    @Size(max = 500, message = "Location must not exceed 500 characters")
    private String location;

    @Schema(description = "Priority level (Low, Medium, High)", example = "High", defaultValue = "Medium")
    @Pattern(regexp = "Low|Medium|High", message = "Priority must be one of: Low, Medium, High")
    private String priority = "Medium";

    @Schema(description = "Job category / type", example = "ซ่อมบำรุง", defaultValue = "ซ่อมบำรุง")
    @Size(max = 100, message = "Job type must not exceed 100 characters")
    private String jobType = "ซ่อมบำรุง";

    @Schema(description = "Detailed description", example = "ตรวจสอบแอร์ไม่เย็น ล้างฟิลเตอร์และวัดแรงดันน้ำยา")
    private String description = "";

    @Schema(description = "Assigned technician", example = "สมชาย ใจดี", defaultValue = "สมชาย ใจดี")
    @Size(max = 255, message = "Technician name must not exceed 255 characters")
    private String technician = "สมชาย ใจดี";

    @Schema(description = "Assigned technician User ID (optional)", example = "3")
    private Long assignedTechnicianId;

    public CreateJobRequest() {
    }

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
}
