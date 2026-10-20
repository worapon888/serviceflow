package com.serviceflow.mapper;

import com.serviceflow.dto.request.CreateJobRequest;
import com.serviceflow.dto.response.JobResponse;
import com.serviceflow.entity.JobEntity;
import com.serviceflow.entity.JobStatus;
import org.springframework.stereotype.Component;

@Component
public class JobMapper {

    public JobResponse toResponse(JobEntity entity) {
        if (entity == null) {
            return null;
        }

        JobResponse response = new JobResponse();
        response.setId(entity.getId());
        response.setTitle(entity.getTitle());
        response.setClient(entity.getClient());
        response.setAppointmentDate(entity.getAppointmentDate());
        response.setAppointmentTime(entity.getAppointmentTime());
        response.setLocation(entity.getLocation());
        response.setStatus(entity.getStatus());
        response.setStatusLabel(entity.getStatus() != null ? entity.getStatus().getThaiLabel() : null);
        response.setPriority(entity.getPriority());
        response.setJobType(entity.getJobType());
        if (entity.getAssignedTechnician() != null) {
            response.setAssignedTechnicianId(entity.getAssignedTechnician().getId());
            response.setTechnician(entity.getAssignedTechnician().getFullName() != null
                    ? entity.getAssignedTechnician().getFullName()
                    : entity.getTechnician());
        } else {
            response.setTechnician(entity.getTechnician());
        }
        response.setStatusNote(entity.getStatusNote());
        response.setVersion(entity.getVersion());
        response.setCreatedAt(entity.getCreatedAt());
        response.setUpdatedAt(entity.getUpdatedAt());
        response.setPhotoCount(entity.getPhotos() != null ? entity.getPhotos().size() : 0);

        return response;
    }

    public JobEntity toEntity(CreateJobRequest request, String generatedId) {
        if (request == null) {
            return null;
        }

        String targetId = (request.getId() != null && !request.getId().trim().isEmpty())
                ? request.getId().trim()
                : generatedId;

        JobEntity entity = new JobEntity();
        entity.setId(targetId);
        entity.setTitle(request.getTitle().trim());
        entity.setClient(request.getClient().trim());
        entity.setAppointmentDate(request.getAppointmentDate().trim());
        entity.setAppointmentTime(request.getAppointmentTime().trim());
        entity.setLocation(request.getLocation().trim());
        entity.setStatus(JobStatus.PENDING); // New jobs always start as PENDING
        entity.setPriority(request.getPriority() != null ? request.getPriority() : "Medium");
        entity.setJobType(request.getJobType() != null ? request.getJobType() : "ซ่อมบำรุง");
        entity.setDescription(request.getDescription() != null ? request.getDescription().trim() : "");
        entity.setTechnician(request.getTechnician() != null && !request.getTechnician().trim().isEmpty()
                ? request.getTechnician().trim()
                : "สมชาย ใจดี");
        entity.setStatusNote("");

        return entity;
    }
}
