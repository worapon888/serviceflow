package com.serviceflow.mapper;

import com.serviceflow.dto.response.JobPhotoResponse;
import com.serviceflow.entity.JobPhotoEntity;
import org.springframework.stereotype.Component;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Component
public class JobPhotoMapper {

    public JobPhotoResponse toResponse(JobPhotoEntity entity) {
        if (entity == null) {
            return null;
        }

        String jobId = entity.getJob() != null ? entity.getJob().getId() : "";
        String encodedJobId = URLEncoder.encode(jobId, StandardCharsets.UTF_8);
        String contentUrl = "/api/v1/jobs/" + encodedJobId + "/photos/" + entity.getId() + "/content";

        return new JobPhotoResponse(
                entity.getId(),
                jobId,
                entity.getPhotoType(),
                entity.getNote(),
                entity.getCreatedAt(),
                contentUrl,
                entity.getStorageKey()
        );
    }
}
