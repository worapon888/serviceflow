package com.serviceflow.storage;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.core.io.Resource;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LocalPhotoStorageServiceTest {

    @TempDir
    Path tempDir;

    private LocalPhotoStorageService storageService;

    @BeforeEach
    void setUp() {
        storageService = new LocalPhotoStorageService(tempDir.toString());
        storageService.init();
    }

    @Test
    @DisplayName("Should successfully store, load, and delete a photo file")
    void testStoreLoadDelete() throws IOException {
        String content = "fake-image-bytes";
        ByteArrayInputStream is = new ByteArrayInputStream(content.getBytes(StandardCharsets.UTF_8));

        String storageKey = storageService.storePhoto("#00010", is, "jpg");
        assertThat(storageKey).isNotNull();
        assertThat(storageKey).contains("#00010").endsWith(".jpg");
        assertThat(storageService.exists(storageKey)).isTrue();

        Resource resource = storageService.loadPhotoAsResource(storageKey);
        assertThat(resource.exists()).isTrue();
        assertThat(resource.contentLength()).isEqualTo(content.getBytes(StandardCharsets.UTF_8).length);

        boolean deleted = storageService.deletePhoto(storageKey);
        assertThat(deleted).isTrue();
        assertThat(storageService.exists(storageKey)).isFalse();
    }

    @Test
    @DisplayName("Should block path traversal attempts")
    void testPathTraversalDefense() {
        assertThatThrownBy(() -> storageService.loadPhotoAsResource("../../etc/passwd"))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("Path traversal");
    }
}
