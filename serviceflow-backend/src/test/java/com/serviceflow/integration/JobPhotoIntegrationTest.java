package com.serviceflow.integration;

import com.serviceflow.dto.request.LoginRequest;
import com.serviceflow.dto.response.ApiResponse;
import com.serviceflow.dto.response.AuthResponse;
import com.serviceflow.dto.response.ErrorResponse;
import com.serviceflow.dto.response.JobPhotoResponse;
import com.serviceflow.entity.JobEntity;
import com.serviceflow.entity.JobStatus;
import com.serviceflow.entity.UserEntity;
import com.serviceflow.repository.JobPhotoRepository;
import com.serviceflow.repository.JobRepository;
import com.serviceflow.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class JobPhotoIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private JobRepository jobRepository;

    @Autowired
    private JobPhotoRepository jobPhotoRepository;

    @Autowired
    private UserRepository userRepository;

    private String baseUrl;
    private String authUrl;

    private HttpHeaders adminHeaders;
    private HttpHeaders dispatcherHeaders;
    private HttpHeaders tech1Headers;
    private HttpHeaders tech2Headers;

    private UserEntity tech1User;
    private UserEntity tech2User;

    // Standard valid JPEG byte header: FF D8 FF
    private final byte[] validJpegBytes = new byte[]{
            (byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0, 16,
            'J', 'F', 'I', 'F', 0, 1, 1, 1, 0, 72, 0, 72, 0, 0
    };

    // Standard valid PNG byte header: 89 50 4E 47 0D 0A 1A 0A
    private final byte[] validPngBytes = new byte[]{
            (byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
            0, 0, 0, 13, 'I', 'H', 'D', 'R'
    };

    private URI photosUri(String jobId) {
        return UriComponentsBuilder.fromHttpUrl(baseUrl)
                .pathSegment(jobId, "photos")
                .build()
                .toUri();
    }

    private URI photoContentUri(String jobId, String photoId) {
        return UriComponentsBuilder.fromHttpUrl(baseUrl)
                .pathSegment(jobId, "photos", photoId, "content")
                .build()
                .toUri();
    }

    private URI photoDeleteUri(String jobId, String photoId) {
        return UriComponentsBuilder.fromHttpUrl(baseUrl)
                .pathSegment(jobId, "photos", photoId)
                .build()
                .toUri();
    }

    private HttpHeaders loginAndGetHeaders(String username, String password) {
        LoginRequest req = new LoginRequest(username, password);
        ResponseEntity<ApiResponse<AuthResponse>> res = restTemplate.exchange(
                authUrl + "/login",
                HttpMethod.POST,
                new HttpEntity<>(req),
                new ParameterizedTypeReference<>() {}
        );
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        String token = res.getBody().getData().getAccessToken();
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        return headers;
    }

    private HttpEntity<MultiValueMap<String, Object>> createMultipartRequest(
            byte[] fileBytes, String filename, String photoType, String note, HttpHeaders authHeaders) {

        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        if (fileBytes != null) {
            ByteArrayResource resource = new ByteArrayResource(fileBytes) {
                @Override
                public String getFilename() {
                    return filename;
                }
            };
            body.add("image", resource);
        }
        if (photoType != null) {
            body.add("photoType", photoType);
        }
        if (note != null) {
            body.add("note", note);
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);
        if (authHeaders != null && authHeaders.containsKey(HttpHeaders.AUTHORIZATION)) {
            headers.put(HttpHeaders.AUTHORIZATION, authHeaders.get(HttpHeaders.AUTHORIZATION));
        }

        return new HttpEntity<>(body, headers);
    }

    @BeforeEach
    void setUp() {
        baseUrl = "http://localhost:" + port + "/api/v1/jobs";
        authUrl = "http://localhost:" + port + "/api/v1/auth";
        restTemplate.getRestTemplate().setRequestFactory(new HttpComponentsClientHttpRequestFactory());

        jobPhotoRepository.deleteAll();
        jobRepository.deleteAll();

        adminHeaders = loginAndGetHeaders("admin", "Admin@123456");
        dispatcherHeaders = loginAndGetHeaders("dispatcher", "Dispatcher@123");
        tech1Headers = loginAndGetHeaders("technician", "Technician@123");
        tech2Headers = loginAndGetHeaders("technician2", "Technician@123");

        tech1User = userRepository.findByUsername("technician").orElseThrow();
        tech2User = userRepository.findByUsername("technician2").orElseThrow();
    }

    @Test
    @DisplayName("1. Upload JPEG successfully by ADMIN")
    void testUploadJpeg_Success() {
        JobEntity job = new JobEntity("#00010", "AC Repair", "Client A", "วันนี้", "09:00", "Loc A",
                JobStatus.PENDING, "High", "ซ่อมบำรุง", "", tech1User.getFullName(), "");
        job.setAssignedTechnician(tech1User);
        jobRepository.save(job);

        HttpEntity<MultiValueMap<String, Object>> req = createMultipartRequest(
                validJpegBytes, "before_repair.jpg", "BEFORE", "สภาพเครื่องก่อนซ่อม", adminHeaders);

        ResponseEntity<ApiResponse<JobPhotoResponse>> res = restTemplate.exchange(
                photosUri("#00010"),
                HttpMethod.POST,
                req,
                new ParameterizedTypeReference<>() {}
        );

        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(res.getBody()).isNotNull();
        JobPhotoResponse photo = res.getBody().getData();
        assertThat(photo.getId()).isNotBlank();
        assertThat(photo.getJobId()).isEqualTo("#00010");
        assertThat(photo.getPhotoType()).isEqualTo("BEFORE");
        assertThat(photo.getNote()).isEqualTo("สภาพเครื่องก่อนซ่อม");
        assertThat(photo.getUrl()).contains(photo.getId());
        assertThat(photo.getStorageKey()).contains("#00010").endsWith(".jpg");
    }

    @Test
    @DisplayName("2. Upload PNG successfully by DISPATCHER")
    void testUploadPng_Success() {
        JobEntity job = new JobEntity("#00011", "Wiring", "Client B", "วันนี้", "10:00", "Loc B",
                JobStatus.IN_PROGRESS, "Medium", "ติดตั้ง", "", tech2User.getFullName(), "");
        job.setAssignedTechnician(tech2User);
        jobRepository.save(job);

        HttpEntity<MultiValueMap<String, Object>> req = createMultipartRequest(
                validPngBytes, "after_wiring.png", "AFTER", "งานเรียบร้อย", dispatcherHeaders);

        ResponseEntity<ApiResponse<JobPhotoResponse>> res = restTemplate.exchange(
                photosUri("#00011"),
                HttpMethod.POST,
                req,
                new ParameterizedTypeReference<>() {}
        );

        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        JobPhotoResponse photo = res.getBody().getData();
        assertThat(photo.getPhotoType()).isEqualTo("AFTER");
        assertThat(photo.getStorageKey()).endsWith(".png");
    }

    @Test
    @DisplayName("3. Upload with missing file returns 400 Bad Request")
    void testUploadMissingFile_Returns400() {
        JobEntity job = new JobEntity("#00012", "Inspection", "Client C", "วันนี้", "11:00", "Loc C",
                JobStatus.PENDING, "Low", "ตรวจสอบ", "", tech1User.getFullName(), "");
        job.setAssignedTechnician(tech1User);
        jobRepository.save(job);

        HttpEntity<MultiValueMap<String, Object>> req = createMultipartRequest(
                null, null, "BEFORE", "No file attached", adminHeaders);

        ResponseEntity<ErrorResponse> res = restTemplate.exchange(
                photosUri("#00012"),
                HttpMethod.POST,
                req,
                ErrorResponse.class
        );

        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    @DisplayName("4. Upload file with invalid signature (fake JPG) returns 400 Bad Request")
    void testUploadInvalidSignature_Returns400() {
        JobEntity job = new JobEntity("#00013", "Testing", "Client D", "วันนี้", "12:00", "Loc D",
                JobStatus.PENDING, "Medium", "ซ่อมบำรุง", "", tech1User.getFullName(), "");
        job.setAssignedTechnician(tech1User);
        jobRepository.save(job);

        byte[] fakeBytes = "Plain text disguised as picture".getBytes(StandardCharsets.UTF_8);
        HttpEntity<MultiValueMap<String, Object>> req = createMultipartRequest(
                fakeBytes, "malicious.jpg", "BEFORE", "note", adminHeaders);

        ResponseEntity<ErrorResponse> res = restTemplate.exchange(
                photosUri("#00013"),
                HttpMethod.POST,
                req,
                ErrorResponse.class
        );

        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(res.getBody().getMessage()).containsIgnoringCase("invalid file signature");
    }

    @Test
    @DisplayName("5. Upload without JWT returns 401 Unauthorized")
    void testUploadWithoutJwt_Returns401() {
        JobEntity job = new JobEntity("#00014", "Job 14", "Client E", "วันนี้", "13:00", "Loc E",
                JobStatus.PENDING, "Low", "ซ่อมบำรุง", "", tech1User.getFullName(), "");
        job.setAssignedTechnician(tech1User);
        jobRepository.save(job);

        HttpHeaders emptyHeaders = new HttpHeaders();
        HttpEntity<MultiValueMap<String, Object>> req = createMultipartRequest(
                validJpegBytes, "photo.jpg", "BEFORE", "note", emptyHeaders);

        ResponseEntity<String> res = restTemplate.exchange(
                photosUri("#00014"),
                HttpMethod.POST,
                req,
                String.class
        );

        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    @DisplayName("6. Upload to non-existing Job ID returns 404 Not Found")
    void testUploadNonExistingJob_Returns404() {
        HttpEntity<MultiValueMap<String, Object>> req = createMultipartRequest(
                validJpegBytes, "photo.jpg", "BEFORE", "note", adminHeaders);

        ResponseEntity<ErrorResponse> res = restTemplate.exchange(
                photosUri("#NON_EXISTENT"),
                HttpMethod.POST,
                req,
                ErrorResponse.class
        );

        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    @DisplayName("7. TECHNICIAN: Can upload photo to own assigned job")
    void testTechnician_UploadOwnJob_Success() {
        JobEntity job = new JobEntity("#00015", "Tech 1 Job", "Client F", "วันนี้", "14:00", "Loc F",
                JobStatus.PENDING, "High", "ซ่อมบำรุง", "", tech1User.getFullName(), "");
        job.setAssignedTechnician(tech1User);
        jobRepository.save(job);

        HttpEntity<MultiValueMap<String, Object>> req = createMultipartRequest(
                validJpegBytes, "tech1_photo.jpg", "BEFORE", "ช่าง 1 ถ่ายรูป", tech1Headers);

        ResponseEntity<ApiResponse<JobPhotoResponse>> res = restTemplate.exchange(
                photosUri("#00015"),
                HttpMethod.POST,
                req,
                new ParameterizedTypeReference<>() {}
        );

        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(res.getBody().getData().getJobId()).isEqualTo("#00015");
    }

    @Test
    @DisplayName("8. TECHNICIAN: Uploading photo to another technician's job returns 403 Forbidden")
    void testTechnician_UploadOtherJob_Returns403() {
        // Job assigned to Tech 2
        JobEntity job = new JobEntity("#00016", "Tech 2 Exclusive Job", "Client G", "วันนี้", "15:00", "Loc G",
                JobStatus.PENDING, "High", "ซ่อมบำรุง", "", tech2User.getFullName(), "");
        job.setAssignedTechnician(tech2User);
        jobRepository.save(job);

        // Tech 1 attempts to upload photo to Tech 2's job
        HttpEntity<MultiValueMap<String, Object>> req = createMultipartRequest(
                validJpegBytes, "intrusion.jpg", "BEFORE", "Tech 1 tampering", tech1Headers);

        ResponseEntity<ErrorResponse> res = restTemplate.exchange(
                photosUri("#00016"),
                HttpMethod.POST,
                req,
                ErrorResponse.class
        );

        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    @DisplayName("9. GET Photo List: Returns list ordered newest to oldest")
    void testGetPhotoList_OrderedNewestFirst() throws InterruptedException {
        JobEntity job = new JobEntity("#00017", "Job 17", "Client H", "วันนี้", "16:00", "Loc H",
                JobStatus.PENDING, "Low", "ตรวจสอบ", "", tech1User.getFullName(), "");
        job.setAssignedTechnician(tech1User);
        jobRepository.save(job);

        // Upload first photo
        HttpEntity<MultiValueMap<String, Object>> req1 = createMultipartRequest(
                validJpegBytes, "first.jpg", "BEFORE", "First photo", adminHeaders);
        restTemplate.exchange(photosUri("#00017"), HttpMethod.POST, req1, String.class);

        Thread.sleep(50);

        // Upload second photo
        HttpEntity<MultiValueMap<String, Object>> req2 = createMultipartRequest(
                validPngBytes, "second.png", "AFTER", "Second photo", adminHeaders);
        restTemplate.exchange(photosUri("#00017"), HttpMethod.POST, req2, String.class);

        // Get list
        ResponseEntity<ApiResponse<List<JobPhotoResponse>>> listRes = restTemplate.exchange(
                photosUri("#00017"),
                HttpMethod.GET,
                new HttpEntity<>(adminHeaders),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(listRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        List<JobPhotoResponse> photos = listRes.getBody().getData();
        assertThat(photos).hasSize(2);
        assertThat(photos.get(0).getNote()).isEqualTo("Second photo"); // Newest first
        assertThat(photos.get(1).getNote()).isEqualTo("First photo");
    }

    @Test
    @DisplayName("10. GET Photo Content: Streams binary content with correct Content-Type")
    void testGetPhotoContent_Success() {
        JobEntity job = new JobEntity("#00018", "Job 18", "Client I", "วันนี้", "17:00", "Loc I",
                JobStatus.PENDING, "Medium", "ซ่อมบำรุง", "", tech1User.getFullName(), "");
        job.setAssignedTechnician(tech1User);
        jobRepository.save(job);

        // Upload
        HttpEntity<MultiValueMap<String, Object>> uploadReq = createMultipartRequest(
                validPngBytes, "content_test.png", "BEFORE", "note", adminHeaders);
        ResponseEntity<ApiResponse<JobPhotoResponse>> uploadRes = restTemplate.exchange(
                photosUri("#00018"),
                HttpMethod.POST,
                uploadReq,
                new ParameterizedTypeReference<>() {}
        );
        String photoId = uploadRes.getBody().getData().getId();

        // Stream photo content
        ResponseEntity<byte[]> contentRes = restTemplate.exchange(
                photoContentUri("#00018", photoId),
                HttpMethod.GET,
                new HttpEntity<>(adminHeaders),
                byte[].class
        );

        assertThat(contentRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(contentRes.getHeaders().getContentType()).isEqualTo(MediaType.IMAGE_PNG);
        assertThat(contentRes.getBody()).isEqualTo(validPngBytes);
    }

    @Test
    @DisplayName("11. TECHNICIAN: Cannot download photos from another technician's job (403 Forbidden)")
    void testTechnician_CannotDownloadOtherPhoto_Returns403() {
        JobEntity job = new JobEntity("#00019", "Tech 2 Secret", "Client J", "วันนี้", "18:00", "Loc J",
                JobStatus.PENDING, "High", "ซ่อมบำรุง", "", tech2User.getFullName(), "");
        job.setAssignedTechnician(tech2User);
        jobRepository.save(job);

        // Tech 2 uploads photo
        HttpEntity<MultiValueMap<String, Object>> uploadReq = createMultipartRequest(
                validJpegBytes, "secret.jpg", "BEFORE", "Tech 2 only", tech2Headers);
        ResponseEntity<ApiResponse<JobPhotoResponse>> uploadRes = restTemplate.exchange(
                photosUri("#00019"),
                HttpMethod.POST,
                uploadReq,
                new ParameterizedTypeReference<>() {}
        );
        String photoId = uploadRes.getBody().getData().getId();

        // Tech 1 attempts to download Tech 2's photo
        ResponseEntity<String> downloadRes = restTemplate.exchange(
                photoContentUri("#00019", photoId),
                HttpMethod.GET,
                new HttpEntity<>(tech1Headers),
                String.class
        );

        assertThat(downloadRes.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    @DisplayName("12. DELETE Photo: Successfully deletes photo and prevents cross-job delete")
    void testDeletePhoto_AndPreventCrossJobDelete() {
        JobEntity jobA = new JobEntity("#00020", "Job A", "Client A", "วันนี้", "09:00", "Loc A",
                JobStatus.PENDING, "High", "ซ่อมบำรุง", "", tech1User.getFullName(), "");
        jobA.setAssignedTechnician(tech1User);
        jobRepository.save(jobA);

        JobEntity jobB = new JobEntity("#00021", "Job B", "Client B", "วันนี้", "10:00", "Loc B",
                JobStatus.PENDING, "Medium", "ติดตั้ง", "", tech1User.getFullName(), "");
        jobB.setAssignedTechnician(tech1User);
        jobRepository.save(jobB);

        // Upload photo to Job A
        HttpEntity<MultiValueMap<String, Object>> req = createMultipartRequest(
                validJpegBytes, "jobA.jpg", "BEFORE", "note", adminHeaders);
        ResponseEntity<ApiResponse<JobPhotoResponse>> uploadRes = restTemplate.exchange(
                photosUri("#00020"),
                HttpMethod.POST,
                req,
                new ParameterizedTypeReference<>() {}
        );
        String photoId = uploadRes.getBody().getData().getId();

        // 1. Attempt cross-job delete: trying to delete photoId via Job B URL -> Should fail (400 or 404)
        ResponseEntity<ErrorResponse> crossJobRes = restTemplate.exchange(
                photoDeleteUri("#00021", photoId),
                HttpMethod.DELETE,
                new HttpEntity<>(adminHeaders),
                ErrorResponse.class
        );
        assertThat(crossJobRes.getStatusCode()).isIn(HttpStatus.BAD_REQUEST, HttpStatus.NOT_FOUND);

        // 2. Legitimate delete via Job A URL
        ResponseEntity<ApiResponse<Void>> deleteRes = restTemplate.exchange(
                photoDeleteUri("#00020", photoId),
                HttpMethod.DELETE,
                new HttpEntity<>(adminHeaders),
                new ParameterizedTypeReference<>() {}
        );
        assertThat(deleteRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(jobPhotoRepository.findById(photoId)).isEmpty();
    }
}
