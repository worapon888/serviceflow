package com.serviceflow.controller;

import com.serviceflow.dto.response.ApiResponse;
import com.serviceflow.dto.response.JobPhotoResponse;
import com.serviceflow.service.JobPhotoService;
import com.serviceflow.service.JobPhotoService.PhotoResource;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.core.io.Resource;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.Duration;
import java.util.List;

@RestController
@RequestMapping("/api/v1/jobs/{jobId}/photos")
@Tag(name = "Job Photo Management", description = "Endpoints for uploading, listing, downloading, and deleting job photos with RBAC and signature validation")
@SecurityRequirement(name = "bearerAuth")
public class JobPhotoController {

    private final JobPhotoService jobPhotoService;

    public JobPhotoController(JobPhotoService jobPhotoService) {
        this.jobPhotoService = jobPhotoService;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload photo for a job", description = "Uploads a photo (JPEG, PNG, WebP) with photoType (BEFORE/AFTER) and optional note. Validates magic bytes signature.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Photo uploaded and attached successfully"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Invalid file signature, missing parameters, or file > 10MB"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Unauthenticated - missing or invalid JWT"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Forbidden - Technician cannot upload to another technician's job"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Job not found")
    })
    public ResponseEntity<ApiResponse<JobPhotoResponse>> uploadPhoto(
            @Parameter(description = "Job ID (e.g. #00037 or %2300037)") @PathVariable String jobId,
            @Parameter(description = "Image file binary (JPEG, PNG, WebP)") @RequestParam("image") MultipartFile image,
            @Parameter(description = "Photo Type: BEFORE or AFTER") @RequestParam("photoType") String photoType,
            @Parameter(description = "Optional technician notes") @RequestParam(value = "note", required = false) String note
    ) {
        JobPhotoResponse response = jobPhotoService.uploadPhoto(jobId, image, photoType, note);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok("Photo uploaded successfully", response));
    }

    @GetMapping
    @Operation(summary = "List job photos", description = "Retrieves all photos attached to the job ordered from newest to oldest.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Photo list retrieved successfully"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Unauthenticated"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Forbidden"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Job not found")
    })
    public ResponseEntity<ApiResponse<List<JobPhotoResponse>>> getJobPhotos(
            @Parameter(description = "Job ID (e.g. #00037 or %2300037)") @PathVariable String jobId
    ) {
        List<JobPhotoResponse> photos = jobPhotoService.getJobPhotos(jobId);
        return ResponseEntity.ok(ApiResponse.ok(photos));
    }

    @GetMapping("/{photoId}/content")
    @Operation(summary = "Download / Stream photo image content", description = "Streams photo binary content with correct Content-Type (image/jpeg, image/png, image/webp). Requires Bearer JWT token.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Photo binary streamed successfully",
                    content = @Content(mediaType = "image/*")),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Unauthenticated"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Forbidden - Technician cannot view another technician's photos"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Photo or Job not found, or cross-job mismatch")
    })
    public ResponseEntity<Resource> getPhotoContent(
            @Parameter(description = "Job ID") @PathVariable String jobId,
            @Parameter(description = "Photo ID") @PathVariable String photoId
    ) {
        PhotoResource photoResource = jobPhotoService.getPhotoContent(jobId, photoId);

        return ResponseEntity.ok()
                .contentType(photoResource.mediaType())
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + photoResource.filename() + "\"")
                .cacheControl(CacheControl.maxAge(Duration.ofDays(1)).cachePrivate())
                .body(photoResource.resource());
    }

    @DeleteMapping("/{photoId}")
    @Operation(summary = "Delete job photo", description = "Deletes photo metadata from database and file from storage. Prevents cross-job deletion.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Photo deleted successfully"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Cross-job deletion mismatch"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Unauthenticated"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Forbidden - Unauthorized to delete"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Photo not found")
    })
    public ResponseEntity<ApiResponse<Void>> deletePhoto(
            @Parameter(description = "Job ID") @PathVariable String jobId,
            @Parameter(description = "Photo ID") @PathVariable String photoId
    ) {
        jobPhotoService.deletePhoto(jobId, photoId);
        return ResponseEntity.ok(ApiResponse.ok("Photo deleted successfully", null));
    }
}
