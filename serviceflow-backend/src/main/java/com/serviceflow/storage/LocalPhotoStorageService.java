package com.serviceflow.storage;

import com.serviceflow.exception.PhotoNotFoundException;
import com.serviceflow.exception.StorageException;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.nio.file.*;
import java.util.UUID;

@Service
@ConditionalOnProperty(name = "serviceflow.storage.type", havingValue = "local", matchIfMissing = true)
public class LocalPhotoStorageService implements PhotoStorageService {

    private static final Logger log = LoggerFactory.getLogger(LocalPhotoStorageService.class);

    private final Path rootLocation;

    public LocalPhotoStorageService(@Value("${serviceflow.storage.photo-dir:#{systemProperties['user.home'] + '/serviceflow_storage/photos'}}") String photoDir) {
        this.rootLocation = Paths.get(photoDir).toAbsolutePath().normalize();
    }

    @PostConstruct
    public void init() {
        try {
            Files.createDirectories(rootLocation);
            log.info("Initialized local photo storage directory at: {}", rootLocation);
        } catch (IOException e) {
            throw new StorageException("Could not initialize local photo storage directory: " + rootLocation, e);
        }
    }

    @Override
    public String storePhoto(String jobId, InputStream inputStream, String extension) throws IOException {
        String safeJobId = sanitizeDirectoryName(jobId);
        Path jobDirectory = rootLocation.resolve(safeJobId).normalize().toAbsolutePath();

        if (!jobDirectory.startsWith(rootLocation)) {
            throw new SecurityException("Path traversal attempt detected in job directory: " + jobId);
        }

        Files.createDirectories(jobDirectory);

        String randomFileName = UUID.randomUUID() + "." + extension.toLowerCase();
        Path destinationFile = jobDirectory.resolve(randomFileName).normalize().toAbsolutePath();

        if (!destinationFile.startsWith(rootLocation)) {
            throw new SecurityException("Path traversal attempt detected in destination path: " + destinationFile);
        }

        Files.copy(inputStream, destinationFile, StandardCopyOption.REPLACE_EXISTING);
        log.debug("Saved photo file to disk: {}", destinationFile);

        // Return relative storage key (e.g., "#00037/uuid.jpg")
        return safeJobId + "/" + randomFileName;
    }

    @Override
    public Resource loadPhotoAsResource(String storageKey) throws IOException {
        if (storageKey == null || storageKey.isBlank()) {
            throw new PhotoNotFoundException("Storage key is required");
        }

        Path resolvedFile = rootLocation.resolve(storageKey).normalize().toAbsolutePath();

        if (!resolvedFile.startsWith(rootLocation)) {
            throw new SecurityException("Path traversal attempt detected for storage key: " + storageKey);
        }

        if (!Files.exists(resolvedFile) || !Files.isReadable(resolvedFile)) {
            log.warn("Photo file does not exist or is not readable: {}", resolvedFile);
            throw new PhotoNotFoundException("Photo file not found on disk");
        }

        try {
            Resource resource = new UrlResource(resolvedFile.toUri());
            if (resource.exists() && resource.isReadable()) {
                return resource;
            } else {
                throw new PhotoNotFoundException("Could not read photo file: " + storageKey);
            }
        } catch (MalformedURLException e) {
            throw new StorageException("Malformed URL for storage key: " + storageKey, e);
        }
    }

    @Override
    public boolean deletePhoto(String storageKey) {
        if (storageKey == null || storageKey.isBlank()) {
            return false;
        }

        try {
            Path resolvedFile = rootLocation.resolve(storageKey).normalize().toAbsolutePath();

            if (!resolvedFile.startsWith(rootLocation)) {
                log.warn("Path traversal detected during photo deletion for key: {}", storageKey);
                return false;
            }

            boolean deleted = Files.deleteIfExists(resolvedFile);
            if (deleted) {
                log.debug("Deleted photo file from disk: {}", resolvedFile);
            } else {
                log.warn("Photo file did not exist on disk when deleting: {}", resolvedFile);
            }
            return deleted;
        } catch (IOException e) {
            log.error("Failed to delete photo file on disk for key: {}", storageKey, e);
            return false;
        }
    }

    @Override
    public boolean exists(String storageKey) {
        if (storageKey == null || storageKey.isBlank()) {
            return false;
        }
        Path resolvedFile = rootLocation.resolve(storageKey).normalize().toAbsolutePath();
        return resolvedFile.startsWith(rootLocation) && Files.exists(resolvedFile);
    }

    public Path getRootLocation() {
        return rootLocation;
    }

    private String sanitizeDirectoryName(String name) {
        if (name == null || name.isBlank()) {
            return "general";
        }
        // Preserve alphanumeric, underscore, hyphen, and hash tag #
        String sanitized = name.trim().replaceAll("[^a-zA-Z0-9_#-]", "_");
        return sanitized.isEmpty() ? "general" : sanitized;
    }
}
