package com.serviceflow.storage;

import org.springframework.core.io.Resource;

import java.io.IOException;
import java.io.InputStream;

public interface PhotoStorageService {

    /**
     * Stores the photo content safely and returns the storage key.
     *
     * @param jobId the ID of the job this photo belongs to
     * @param inputStream data stream of the photo
     * @param extension canonical file extension (e.g. "jpg", "png", "webp")
     * @return storage key (relative identifier, e.g. "jobs/#00037/uuid.jpg")
     * @throws IOException if saving fails
     */
    String storePhoto(String jobId, InputStream inputStream, String extension) throws IOException;

    /**
     * Loads the photo as a Spring Resource for streaming back to clients.
     *
     * @param storageKey the relative storage key
     * @return Resource representing the photo file
     * @throws IOException if reading fails
     */
    Resource loadPhotoAsResource(String storageKey) throws IOException;

    /**
     * Deletes the photo from storage.
     *
     * @param storageKey the relative storage key
     * @return true if deleted, false if file did not exist
     */
    boolean deletePhoto(String storageKey);

    /**
     * Checks if a photo with the given storage key exists.
     *
     * @param storageKey the relative storage key
     * @return true if exists
     */
    boolean exists(String storageKey);
}
