package com.serviceflow.service;

import com.serviceflow.dto.response.JobPhotoResponse;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public interface JobPhotoService {

    record PhotoResource(Resource resource, MediaType mediaType, String filename) {}

    /**
     * Uploads and attaches a photo to a job with validation and compensation cleanup.
     */
    JobPhotoResponse uploadPhoto(String jobId, MultipartFile file, String photoType, String note);

    /**
     * Retrieves all photos for a job, sorted newest to oldest.
     */
    List<JobPhotoResponse> getJobPhotos(String jobId);

    /**
     * Retrieves photo binary content with authorization and cross-job checks.
     */
    PhotoResource getPhotoContent(String jobId, String photoId);

    /**
     * Deletes a photo and its underlying file with authorization and cross-job checks.
     */
    void deletePhoto(String jobId, String photoId);
}
