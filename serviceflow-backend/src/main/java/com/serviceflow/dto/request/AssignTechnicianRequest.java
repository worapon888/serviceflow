package com.serviceflow.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

@Schema(description = "Request payload to assign a technician to a job")
public class AssignTechnicianRequest {

    @Schema(description = "User ID of the technician to assign", example = "3", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull(message = "Technician ID is required")
    private Long technicianId;

    public AssignTechnicianRequest() {
    }

    public AssignTechnicianRequest(Long technicianId) {
        this.technicianId = technicianId;
    }

    public Long getTechnicianId() {
        return technicianId;
    }

    public void setTechnicianId(Long technicianId) {
        this.technicianId = technicianId;
    }
}
