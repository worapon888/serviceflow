package com.serviceflow.util;

import com.serviceflow.exception.InvalidFileException;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;

public final class FileSignatureValidator {

    public static final long MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024L; // 10 MB

    public record ImageMetadata(String contentType, String extension) {}

    private FileSignatureValidator() {
    }

    /**
     * Inspects the file's raw magic bytes (file signature) rather than trusting
     * client-provided MIME types or file extensions.
     * Supports JPEG, PNG, and WebP.
     *
     * @param file the uploaded multipart file
     * @return ImageMetadata containing the validated content type and canonical extension
     * @throws InvalidFileException if file is null, empty, oversized, or has an invalid signature
     */
    public static ImageMetadata validate(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new InvalidFileException("Photo file is required and cannot be empty");
        }

        if (file.getSize() > MAX_FILE_SIZE_BYTES) {
            throw new InvalidFileException(String.format("File size exceeds maximum allowed limit of 10MB (size: %.2f MB)",
                    file.getSize() / (1024.0 * 1024.0)));
        }

        byte[] header = new byte[12];
        try (InputStream inputStream = file.getInputStream()) {
            int bytesRead = inputStream.read(header);
            if (bytesRead < 12) {
                throw new InvalidFileException("Uploaded file is too small or corrupt to be a valid image");
            }
        } catch (IOException e) {
            throw new InvalidFileException("Failed to read uploaded file signature: " + e.getMessage(), e);
        }

        // 1. Check JPEG: FF D8 FF
        if ((header[0] & 0xFF) == 0xFF && (header[1] & 0xFF) == 0xD8 && (header[2] & 0xFF) == 0xFF) {
            return new ImageMetadata("image/jpeg", "jpg");
        }

        // 2. Check PNG: 89 50 4E 47 0D 0A 1A 0A (\x89PNG\r\n\x1a\n)
        if ((header[0] & 0xFF) == 0x89 && (header[1] & 0xFF) == 0x50 &&
            (header[2] & 0xFF) == 0x4E && (header[3] & 0xFF) == 0x47 &&
            (header[4] & 0xFF) == 0x0D && (header[5] & 0xFF) == 0x0A &&
            (header[6] & 0xFF) == 0x1A && (header[7] & 0xFF) == 0x0A) {
            return new ImageMetadata("image/png", "png");
        }

        // 3. Check WebP: RIFF (bytes 0-3) and WEBP (bytes 8-11)
        if (header[0] == 'R' && header[1] == 'I' && header[2] == 'F' && header[3] == 'F' &&
            header[8] == 'W' && header[9] == 'E' && header[10] == 'B' && header[11] == 'P') {
            return new ImageMetadata("image/webp", "webp");
        }

        throw new InvalidFileException("Unsupported file type or invalid file signature. Only JPEG, PNG, and WebP are allowed.");
    }
}
