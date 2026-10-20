package com.serviceflow.service;

import com.serviceflow.entity.JobEntity;
import com.serviceflow.entity.JobStatus;
import com.serviceflow.entity.Role;
import com.serviceflow.entity.UserEntity;
import com.serviceflow.mapper.JobPhotoMapper;
import com.serviceflow.repository.JobPhotoRepository;
import com.serviceflow.repository.JobRepository;
import com.serviceflow.security.UserPrincipal;
import com.serviceflow.service.impl.JobPhotoServiceImpl;
import com.serviceflow.storage.PhotoStorageService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.io.InputStream;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class JobPhotoCompensationTest {

    @Mock
    private JobRepository jobRepository;

    @Mock
    private JobPhotoRepository jobPhotoRepository;

    @Mock
    private JobPhotoMapper jobPhotoMapper;

    @Mock
    private PhotoStorageService photoStorageService;

    private JobPhotoServiceImpl jobPhotoService;

    private final byte[] validJpegBytes = new byte[]{
            (byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0, 16,
            'J', 'F', 'I', 'F', 0, 1, 1, 1, 0, 72, 0, 72, 0, 0
    };

    @BeforeEach
    void setUp() {
        jobPhotoService = new JobPhotoServiceImpl(
                jobRepository,
                jobPhotoRepository,
                jobPhotoMapper,
                photoStorageService
        );

        UserPrincipal adminUser = new UserPrincipal(
                1L,
                "admin",
                "admin@serviceflow.com",
                "pass",
                "Admin",
                Role.ADMIN,
                true,
                java.util.Collections.singletonList(new org.springframework.security.core.authority.SimpleGrantedAuthority(Role.ADMIN.getAuthority()))
        );
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(adminUser, null, adminUser.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("Compensation Test: When DB save fails after file is written to storage, file must be deleted")
    void testCompensation_FileCleanedUpOnDbError() throws Exception {
        JobEntity job = new JobEntity("#00099", "Test Job", "Client", "วันนี้", "09:00", "Loc",
                JobStatus.PENDING, "Medium", "ซ่อมบำรุง", "", "Admin", "");
        when(jobRepository.findById("#00099")).thenReturn(Optional.of(job));

        String savedStorageKey = "#00099/compensation-test-uuid.jpg";
        when(photoStorageService.storePhoto(eq("#00099"), any(InputStream.class), eq("jpg")))
                .thenReturn(savedStorageKey);

        // Simulate DB failure on save
        when(jobPhotoRepository.save(any())).thenThrow(new DataIntegrityViolationException("Simulated DB constraint failure"));

        MockMultipartFile file = new MockMultipartFile("image", "photo.jpg", "image/jpeg", validJpegBytes);

        assertThatThrownBy(() -> jobPhotoService.uploadPhoto("#00099", file, "BEFORE", "note"))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("Simulated DB constraint failure");

        // Verify that storageService.deletePhoto was called with the stored key as compensation!
        verify(photoStorageService, times(1)).deletePhoto(savedStorageKey);
    }
}
