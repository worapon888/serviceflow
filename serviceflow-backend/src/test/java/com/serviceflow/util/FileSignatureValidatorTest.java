package com.serviceflow.util;

import com.serviceflow.exception.InvalidFileException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class FileSignatureValidatorTest {

    @Test
    @DisplayName("Should accept valid JPEG file with FF D8 FF magic bytes")
    void testValidJpeg() {
        byte[] jpegBytes = new byte[]{(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0, 16, 'J', 'F', 'I', 'F', 0, 1};
        MockMultipartFile file = new MockMultipartFile("image", "photo.jpg", "image/jpeg", jpegBytes);

        FileSignatureValidator.ImageMetadata metadata = FileSignatureValidator.validate(file);
        assertThat(metadata.contentType()).isEqualTo("image/jpeg");
        assertThat(metadata.extension()).isEqualTo("jpg");
    }

    @Test
    @DisplayName("Should accept valid PNG file with 89 50 4E 47 0D 0A 1A 0A magic bytes")
    void testValidPng() {
        byte[] pngBytes = new byte[]{(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13};
        MockMultipartFile file = new MockMultipartFile("image", "test.png", "image/png", pngBytes);

        FileSignatureValidator.ImageMetadata metadata = FileSignatureValidator.validate(file);
        assertThat(metadata.contentType()).isEqualTo("image/png");
        assertThat(metadata.extension()).isEqualTo("png");
    }

    @Test
    @DisplayName("Should accept valid WebP file with RIFF....WEBP signature")
    void testValidWebP() {
        byte[] webpBytes = new byte[]{
                'R', 'I', 'F', 'F',
                36, 0, 0, 0,
                'W', 'E', 'B', 'P',
                'V', 'P', '8', ' '
        };
        MockMultipartFile file = new MockMultipartFile("image", "sample.webp", "image/webp", webpBytes);

        FileSignatureValidator.ImageMetadata metadata = FileSignatureValidator.validate(file);
        assertThat(metadata.contentType()).isEqualTo("image/webp");
        assertThat(metadata.extension()).isEqualTo("webp");
    }

    @Test
    @DisplayName("Should reject file with spoofed extension and invalid signature")
    void testSpoofedExtension() {
        byte[] textBytes = "This is a plain text file disguised as a JPEG image".getBytes();
        MockMultipartFile file = new MockMultipartFile("image", "malicious.jpg", "image/jpeg", textBytes);

        assertThatThrownBy(() -> FileSignatureValidator.validate(file))
                .isInstanceOf(InvalidFileException.class)
                .hasMessageContaining("Unsupported file type or invalid file signature");
    }

    @Test
    @DisplayName("Should reject empty file")
    void testEmptyFile() {
        MockMultipartFile file = new MockMultipartFile("image", "empty.jpg", "image/jpeg", new byte[0]);

        assertThatThrownBy(() -> FileSignatureValidator.validate(file))
                .isInstanceOf(InvalidFileException.class)
                .hasMessageContaining("empty");
    }

    @Test
    @DisplayName("Should reject file exceeding 10MB limit")
    void testOversizedFile() {
        // Construct mock file reporting size > 10MB
        MockMultipartFile file = new MockMultipartFile("image", "huge.jpg", "image/jpeg", new byte[100]) {
            @Override
            public long getSize() {
                return 11 * 1024 * 1024L;
            }
        };

        assertThatThrownBy(() -> FileSignatureValidator.validate(file))
                .isInstanceOf(InvalidFileException.class)
                .hasMessageContaining("exceeds maximum allowed limit of 10MB");
    }
}
