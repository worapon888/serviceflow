package com.serviceflow.storage;

import com.serviceflow.exception.PhotoNotFoundException;
import com.serviceflow.exception.StorageException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.ResponseInputStream;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.UUID;

/**
 * Cloudflare R2 (S3-Compatible) Photo Storage Implementation.
 * 
 * Architecture Principle:
 * - Buckets are strictly PRIVATE.
 * - Photos are streamed exclusively via Spring Boot authenticated REST endpoints
 *   after validating the user's JWT and verifying Technician / Dispatcher job ownership.
 * - Direct public access to the R2 bucket is prohibited.
 */
@Service
@ConditionalOnProperty(name = "serviceflow.storage.type", havingValue = "r2")
public class R2PhotoStorageService implements PhotoStorageService {

    private static final Logger log = LoggerFactory.getLogger(R2PhotoStorageService.class);

    private final S3Client s3Client;
    private final String bucketName;

    public R2PhotoStorageService(
            S3Client s3Client,
            @Value("${serviceflow.storage.r2.bucket-name:serviceflow-photos}") String bucketName
    ) {
        this.s3Client = s3Client;
        this.bucketName = bucketName;
    }

    @Override
    public String storePhoto(String jobId, InputStream inputStream, String extension) throws IOException {
        String safeJobId = sanitizeKey(jobId);
        String randomFileName = UUID.randomUUID() + "." + extension.toLowerCase();
        String storageKey = safeJobId + "/" + randomFileName;

        try {
            // Read stream into byte array to calculate content length for S3 PutObject
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            inputStream.transferTo(baos);
            byte[] bytes = baos.toByteArray();

            PutObjectRequest putRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(storageKey)
                    .contentType(resolveContentType(extension))
                    .contentLength((long) bytes.length)
                    .build();

            s3Client.putObject(putRequest, RequestBody.fromBytes(bytes));
            log.info("Uploaded photo to Cloudflare R2: bucket={}, key={}, size={} bytes", bucketName, storageKey, bytes.length);

            return storageKey;
        } catch (S3Exception e) {
            log.error("Failed to upload photo to Cloudflare R2: key={}", storageKey, e);
            throw new StorageException("Failed to store photo in Cloudflare R2: " + e.awsErrorDetails().errorMessage(), e);
        }
    }

    @Override
    public Resource loadPhotoAsResource(String storageKey) throws IOException {
        if (storageKey == null || storageKey.isBlank()) {
            throw new PhotoNotFoundException("Storage key is required");
        }

        try {
            GetObjectRequest getRequest = GetObjectRequest.builder()
                    .bucket(bucketName)
                    .key(storageKey)
                    .build();

            ResponseInputStream<GetObjectResponse> s3Stream = s3Client.getObject(getRequest);

            return new InputStreamResource(s3Stream) {
                @Override
                public String getFilename() {
                    return storageKey.substring(storageKey.lastIndexOf('/') + 1);
                }

                @Override
                public long contentLength() {
                    return s3Stream.response().contentLength();
                }
            };
        } catch (NoSuchKeyException e) {
            log.warn("Photo key not found in Cloudflare R2: bucket={}, key={}", bucketName, storageKey);
            throw new PhotoNotFoundException("Photo not found in cloud storage: " + storageKey);
        } catch (S3Exception e) {
            log.error("Failed to retrieve photo from Cloudflare R2: key={}", storageKey, e);
            throw new StorageException("Failed to load photo from Cloudflare R2: " + e.awsErrorDetails().errorMessage(), e);
        }
    }

    @Override
    public boolean deletePhoto(String storageKey) {
        if (storageKey == null || storageKey.isBlank()) {
            return false;
        }

        try {
            DeleteObjectRequest deleteRequest = DeleteObjectRequest.builder()
                    .bucket(bucketName)
                    .key(storageKey)
                    .build();

            s3Client.deleteObject(deleteRequest);
            log.info("Deleted photo from Cloudflare R2: bucket={}, key={}", bucketName, storageKey);
            return true;
        } catch (S3Exception e) {
            log.error("Failed to delete photo from Cloudflare R2: key={}", storageKey, e);
            return false;
        }
    }

    @Override
    public boolean exists(String storageKey) {
        if (storageKey == null || storageKey.isBlank()) {
            return false;
        }

        try {
            HeadObjectRequest headRequest = HeadObjectRequest.builder()
                    .bucket(bucketName)
                    .key(storageKey)
                    .build();

            s3Client.headObject(headRequest);
            return true;
        } catch (NoSuchKeyException e) {
            return false;
        } catch (S3Exception e) {
            if (e.statusCode() == 404) {
                return false;
            }
            log.warn("Error checking existence in Cloudflare R2 for key: {}", storageKey, e);
            return false;
        }
    }

    private String sanitizeKey(String key) {
        if (key == null || key.isBlank()) {
            return "general";
        }
        return key.trim().replaceAll("[^a-zA-Z0-9_#-]", "_");
    }

    private String resolveContentType(String extension) {
        return switch (extension.toLowerCase()) {
            case "png" -> "image/png";
            case "webp" -> "image/webp";
            default -> "image/jpeg";
        };
    }
}
