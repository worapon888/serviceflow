package com.serviceflow.storage;

import com.serviceflow.exception.PhotoNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.io.Resource;
import software.amazon.awssdk.core.ResponseInputStream;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.http.AbortableInputStream;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class R2PhotoStorageServiceTest {

    @Mock
    private S3Client s3Client;

    private R2PhotoStorageService r2StorageService;
    private final String bucketName = "test-r2-bucket";

    @BeforeEach
    void setUp() {
        r2StorageService = new R2PhotoStorageService(s3Client, bucketName);
    }

    @Test
    @DisplayName("Should successfully upload photo to Cloudflare R2")
    void testStorePhoto() throws IOException {
        String data = "test-image-binary-data";
        ByteArrayInputStream bais = new ByteArrayInputStream(data.getBytes(StandardCharsets.UTF_8));

        when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                .thenReturn(PutObjectResponse.builder().build());

        String key = r2StorageService.storePhoto("#00032", bais, "jpg");

        assertThat(key).isNotNull();
        assertThat(key).startsWith("#00032/").endsWith(".jpg");

        ArgumentCaptor<PutObjectRequest> requestCaptor = ArgumentCaptor.forClass(PutObjectRequest.class);
        verify(s3Client).putObject(requestCaptor.capture(), any(RequestBody.class));

        PutObjectRequest captured = requestCaptor.getValue();
        assertThat(captured.bucket()).isEqualTo(bucketName);
        assertThat(captured.key()).isEqualTo(key);
        assertThat(captured.contentType()).isEqualTo("image/jpeg");
    }

    @Test
    @DisplayName("Should load photo from Cloudflare R2 as Spring Resource")
    void testLoadPhotoAsResource() throws IOException {
        String testData = "downloaded-r2-photo-bytes";
        byte[] bytes = testData.getBytes(StandardCharsets.UTF_8);

        GetObjectResponse getResponse = GetObjectResponse.builder()
                .contentLength((long) bytes.length)
                .contentType("image/jpeg")
                .build();

        ResponseInputStream<GetObjectResponse> responseStream = new ResponseInputStream<>(
                getResponse,
                AbortableInputStream.create(new ByteArrayInputStream(bytes))
        );

        when(s3Client.getObject(any(GetObjectRequest.class))).thenReturn(responseStream);

        Resource resource = r2StorageService.loadPhotoAsResource("_00032/sample.jpg");

        assertThat(resource).isNotNull();
        assertThat(resource.contentLength()).isEqualTo(bytes.length);
        assertThat(resource.getFilename()).isEqualTo("sample.jpg");
    }

    @Test
    @DisplayName("Should throw PhotoNotFoundException when key does not exist in R2")
    void testLoadPhotoNotFound() {
        when(s3Client.getObject(any(GetObjectRequest.class)))
                .thenThrow(NoSuchKeyException.builder().message("The specified key does not exist.").build());

        assertThatThrownBy(() -> r2StorageService.loadPhotoAsResource("non-existent-key.jpg"))
                .isInstanceOf(PhotoNotFoundException.class)
                .hasMessageContaining("Photo not found in cloud storage");
    }

    @Test
    @DisplayName("Should successfully delete photo from Cloudflare R2")
    void testDeletePhoto() {
        when(s3Client.deleteObject(any(DeleteObjectRequest.class)))
                .thenReturn(DeleteObjectResponse.builder().build());

        boolean deleted = r2StorageService.deletePhoto("_00032/sample.jpg");
        assertThat(deleted).isTrue();

        verify(s3Client).deleteObject(any(DeleteObjectRequest.class));
    }

    @Test
    @DisplayName("Should correctly check if photo exists in Cloudflare R2")
    void testExists() {
        when(s3Client.headObject(any(HeadObjectRequest.class)))
                .thenReturn(HeadObjectResponse.builder().build());

        assertThat(r2StorageService.exists("_00032/sample.jpg")).isTrue();

        when(s3Client.headObject(any(HeadObjectRequest.class)))
                .thenThrow(NoSuchKeyException.builder().build());

        assertThat(r2StorageService.exists("_00032/missing.jpg")).isFalse();
    }
}
