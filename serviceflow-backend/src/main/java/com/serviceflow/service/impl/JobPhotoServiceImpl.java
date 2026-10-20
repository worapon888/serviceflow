package com.serviceflow.service.impl;

import com.serviceflow.dto.response.JobPhotoResponse;
import com.serviceflow.entity.JobEntity;
import com.serviceflow.entity.JobPhotoEntity;
import com.serviceflow.entity.PhotoType;
import com.serviceflow.entity.Role;
import com.serviceflow.exception.InvalidFileException;
import com.serviceflow.exception.JobNotFoundException;
import com.serviceflow.exception.PhotoNotFoundException;
import com.serviceflow.exception.StorageException;
import com.serviceflow.mapper.JobPhotoMapper;
import com.serviceflow.repository.JobPhotoRepository;
import com.serviceflow.repository.JobRepository;
import com.serviceflow.security.SecurityUtils;
import com.serviceflow.security.UserPrincipal;
import com.serviceflow.service.JobPhotoService;
import com.serviceflow.storage.PhotoStorageService;
import com.serviceflow.util.FileSignatureValidator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.UUID;

@Service
public class JobPhotoServiceImpl implements JobPhotoService {

    private static final Logger log = LoggerFactory.getLogger(JobPhotoServiceImpl.class);

    private final JobRepository jobRepository;
    private final JobPhotoRepository jobPhotoRepository;
    private final JobPhotoMapper jobPhotoMapper;
    private final PhotoStorageService photoStorageService;

    public JobPhotoServiceImpl(
            JobRepository jobRepository,
            JobPhotoRepository jobPhotoRepository,
            JobPhotoMapper jobPhotoMapper,
            PhotoStorageService photoStorageService
    ) {
        this.jobRepository = jobRepository;
        this.jobPhotoRepository = jobPhotoRepository;
        this.jobPhotoMapper = jobPhotoMapper;
        this.photoStorageService = photoStorageService;
    }

    @Override
    @Transactional
    public JobPhotoResponse uploadPhoto(String jobId, MultipartFile file, String photoTypeStr, String note) {
        String normalizedJobId = normalizeJobId(jobId);

        // 1. Verify Authentication
        UserPrincipal currentUser = getCurrentAuthenticatedUser();

        // 2. Verify Job Exists
        JobEntity job = jobRepository.findById(normalizedJobId)
                .orElseThrow(() -> new JobNotFoundException(normalizedJobId));

        // 3. Service Layer RBAC Check
        checkJobAccess(job, currentUser, "upload photo to");

        // 4. Validate PhotoType
        PhotoType photoType = PhotoType.fromString(photoTypeStr);

        // 5. Validate File & File Signature
        FileSignatureValidator.ImageMetadata metadata = FileSignatureValidator.validate(file);

        // 6. Generate Unique Photo ID
        String photoId = "photo_" + System.currentTimeMillis() + "_" + UUID.randomUUID().toString().substring(0, 8);

        // 7. Store File and Compensate if Database Fails
        String storageKey;
        try (InputStream inputStream = file.getInputStream()) {
            storageKey = photoStorageService.storePhoto(job.getId(), inputStream, metadata.extension());
        } catch (IOException e) {
            log.error("Failed to store photo file for job {}: {}", jobId, e.getMessage());
            throw new StorageException("Failed to save uploaded photo to storage: " + e.getMessage(), e);
        }

        JobPhotoEntity entity = new JobPhotoEntity(
                photoId,
                job,
                storageKey,
                photoType.name(),
                note != null ? note.trim() : ""
        );
        entity.setCreatedAt(java.time.OffsetDateTime.now());

        try {
            JobPhotoEntity saved = jobPhotoRepository.save(entity);
            log.info("Successfully attached photo {} to job {} (type: {}, key: {}) by user {}",
                    photoId, jobId, photoType, storageKey, currentUser.getUsername());
            return jobPhotoMapper.toResponse(saved);
        } catch (Exception ex) {
            log.error("Database error saving photo metadata for photo {}; initiating compensation delete of file: {}",
                    photoId, storageKey, ex);
            try {
                photoStorageService.deletePhoto(storageKey);
                log.info("Compensation cleanup completed for storage key: {}", storageKey);
            } catch (Exception cleanupEx) {
                log.error("Compensation cleanup failed for storage key: {}", storageKey, cleanupEx);
            }
            throw ex;
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<JobPhotoResponse> getJobPhotos(String jobId) {
        String normalizedJobId = normalizeJobId(jobId);
        UserPrincipal currentUser = getCurrentAuthenticatedUser();

        JobEntity job = jobRepository.findById(normalizedJobId)
                .orElseThrow(() -> new JobNotFoundException(normalizedJobId));

        checkJobAccess(job, currentUser, "view photos of");

        List<JobPhotoEntity> photos = jobPhotoRepository.findByJobIdOrderByCreatedAtDesc(normalizedJobId);
        return photos.stream()
                .map(jobPhotoMapper::toResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public PhotoResource getPhotoContent(String jobId, String photoId) {
        String normalizedJobId = normalizeJobId(jobId);
        UserPrincipal currentUser = getCurrentAuthenticatedUser();

        JobPhotoEntity photo = jobPhotoRepository.findById(photoId)
                .orElseThrow(() -> new PhotoNotFoundException("Photo not found with ID: " + photoId));

        // Cross-Job Validation
        if (!photo.getJob().getId().equals(normalizedJobId)) {
            log.warn("Photo {} belongs to job {}, not requested job {}", photoId, photo.getJob().getId(), normalizedJobId);
            throw new PhotoNotFoundException("Photo with ID " + photoId + " does not belong to job " + normalizedJobId);
        }

        checkJobAccess(photo.getJob(), currentUser, "download photo of");

        try {
            Resource resource = photoStorageService.loadPhotoAsResource(photo.getImagePath());
            MediaType mediaType = determineMediaType(photo.getImagePath());
            String filename = photoId + getExtensionFromKey(photo.getImagePath());

            return new PhotoResource(resource, mediaType, filename);
        } catch (IOException e) {
            log.error("Failed to load photo resource for photo {}: {}", photoId, e.getMessage());
            throw new StorageException("Failed to read photo content: " + e.getMessage(), e);
        }
    }

    @Override
    @Transactional
    public void deletePhoto(String jobId, String photoId) {
        String normalizedJobId = normalizeJobId(jobId);
        UserPrincipal currentUser = getCurrentAuthenticatedUser();

        JobPhotoEntity photo = jobPhotoRepository.findById(photoId)
                .orElseThrow(() -> new PhotoNotFoundException("Photo not found with ID: " + photoId));

        // Cross-Job Validation
        if (!photo.getJob().getId().equals(normalizedJobId)) {
            log.warn("Attempted cross-job delete: photo {} belongs to job {}, requested delete on job {}",
                    photoId, photo.getJob().getId(), normalizedJobId);
            throw new IllegalArgumentException("Photo with ID " + photoId + " does not belong to job " + normalizedJobId);
        }

        checkJobAccess(photo.getJob(), currentUser, "delete photo of");

        String storageKey = photo.getImagePath();

        // Delete from database
        jobPhotoRepository.delete(photo);
        log.info("Deleted photo metadata {} from database", photoId);

        // Delete underlying file
        boolean deleted = photoStorageService.deletePhoto(storageKey);
        if (!deleted) {
            log.warn("Underlying file was not found on disk during deletion of photo {} (key: {})", photoId, storageKey);
        } else {
            log.info("Deleted underlying file for photo {} (key: {})", photoId, storageKey);
        }
    }

    private String normalizeJobId(String jobId) {
        if (jobId == null) {
            return null;
        }
        String trimmed = jobId.trim();
        while (trimmed.startsWith("%23") || trimmed.startsWith("%2523")) {
            try {
                trimmed = java.net.URLDecoder.decode(trimmed, java.nio.charset.StandardCharsets.UTF_8);
            } catch (Exception e) {
                trimmed = trimmed.replace("%23", "#");
            }
        }
        return trimmed;
    }

    private UserPrincipal getCurrentAuthenticatedUser() {
        return SecurityUtils.getCurrentUser()
                .orElseThrow(() -> new AccessDeniedException("Full authentication is required to access photo resources"));
    }

    private void checkJobAccess(JobEntity job, UserPrincipal user, String action) {
        if (user.getRole() == Role.ADMIN || user.getRole() == Role.DISPATCHER) {
            // ADMIN and DISPATCHER can access photos for any job
            return;
        }

        if (user.getRole() == Role.TECHNICIAN) {
            if (job.getAssignedTechnician() == null || !user.getId().equals(job.getAssignedTechnician().getId())) {
                log.warn("Technician {} unauthorized attempt to {} job {}", user.getId(), action, job.getId());
                throw new AccessDeniedException("Access Denied: You are not authorized to " + action + " jobs assigned to other technicians");
            }
        }
    }

    private MediaType determineMediaType(String storageKey) {
        if (storageKey != null) {
            String lower = storageKey.toLowerCase();
            if (lower.endsWith(".png")) {
                return MediaType.IMAGE_PNG;
            }
            if (lower.endsWith(".webp")) {
                return MediaType.valueOf("image/webp");
            }
        }
        return MediaType.IMAGE_JPEG;
    }

    private String getExtensionFromKey(String storageKey) {
        if (storageKey != null && storageKey.contains(".")) {
            return storageKey.substring(storageKey.lastIndexOf("."));
        }
        return ".jpg";
    }
}
