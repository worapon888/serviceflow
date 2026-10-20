package com.serviceflow.service;

import com.serviceflow.dto.request.CreateJobRequest;
import com.serviceflow.dto.request.UpdateJobStatusRequest;
import com.serviceflow.dto.response.JobResponse;
import com.serviceflow.dto.response.JobStatisticsResponse;
import com.serviceflow.dto.response.PageResponse;
import com.serviceflow.entity.JobEntity;
import com.serviceflow.entity.JobStatus;
import com.serviceflow.exception.DuplicateJobException;
import com.serviceflow.exception.InvalidStatusTransitionException;
import com.serviceflow.exception.JobNotFoundException;
import com.serviceflow.mapper.JobMapper;
import com.serviceflow.repository.JobRepository;
import com.serviceflow.service.impl.JobServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class JobServiceTest {

    @Mock
    private JobRepository jobRepository;

    @Mock
    private com.serviceflow.repository.UserRepository userRepository;

    @Spy
    private JobMapper jobMapper = new JobMapper();

    @InjectMocks
    private JobServiceImpl jobService;

    private JobEntity pendingJob;
    private JobEntity inProgressJob;
    private JobEntity completedJob;

    @BeforeEach
    void setUp() {
        pendingJob = new JobEntity("#00028", "ตรวจล้างแอร์", "บริษัท ABC จำกัด",
                "วันนี้", "09:00", "123 ถนนสุขุมวิท", JobStatus.PENDING, "High", "ซ่อมบำรุง",
                "ล้างแอร์ 3 เครื่อง", "สมชาย ใจดี", "");
        pendingJob.setVersion(0L);

        inProgressJob = new JobEntity("#00026", "ติดตั้ง Router", "บริษัท XYZ จำกัด",
                "วันนี้", "11:00", "45 ถนนพหลโยธิน", JobStatus.IN_PROGRESS, "Medium", "ติดตั้ง",
                "ติดตั้งเราเตอร์", "สมชาย ใจดี", "กำลังติดตั้ง");
        inProgressJob.setVersion(1L);

        completedJob = new JobEntity("#00025", "ตรวจระบบไฟฟ้า", "ร้านค้า ตัวอย่าง",
                "วันนี้", "14:00", "88 ถนนสีลม", JobStatus.COMPLETED, "Low", "ตรวจสอบ",
                "ตรวจเสร็จแล้ว", "สมชาย ใจดี", "ปิดงานเรียบร้อย");
        completedJob.setVersion(2L);
    }

    @Test
    @DisplayName("createJob should generate ID and persist with PENDING status")
    void testCreateJob_Success() {
        CreateJobRequest request = new CreateJobRequest();
        request.setTitle("ซ่อมตู้เย็น");
        request.setClient("คุณสมศรี");
        request.setAppointmentDate("วันนี้");
        request.setAppointmentTime("15:00");
        request.setLocation("12/4 ซอยทองหล่อ 10");

        when(jobRepository.getNextSequenceValue()).thenReturn(Optional.of(29L));
        when(jobRepository.save(any(JobEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

        JobResponse response = jobService.createJob(request);

        assertThat(response).isNotNull();
        assertThat(response.getId()).isEqualTo("#00029");
        assertThat(response.getStatus()).isEqualTo(JobStatus.PENDING);
        assertThat(response.getStatusLabel()).isEqualTo("รอดำเนินการ");
        assertThat(response.getTitle()).isEqualTo("ซ่อมตู้เย็น");
        verify(jobRepository, times(1)).save(any(JobEntity.class));
    }

    @Test
    @DisplayName("createJob with duplicate ID should throw DuplicateJobException")
    void testCreateJob_DuplicateIdThrowsException() {
        CreateJobRequest request = new CreateJobRequest();
        request.setId("#00028");
        request.setTitle("ตรวจล้างแอร์");
        request.setClient("บริษัท ABC จำกัด");
        request.setAppointmentDate("วันนี้");
        request.setAppointmentTime("09:00");
        request.setLocation("123 ถนนสุขุมวิท");

        when(jobRepository.existsById("#00028")).thenReturn(true);

        assertThatThrownBy(() -> jobService.createJob(request))
                .isInstanceOf(DuplicateJobException.class)
                .hasMessageContaining("#00028");

        verify(jobRepository, never()).save(any(JobEntity.class));
    }

    @Test
    @DisplayName("getJobById should return JobResponse when job exists")
    void testGetJobById_Found() {
        when(jobRepository.findById("#00028")).thenReturn(Optional.of(pendingJob));

        JobResponse response = jobService.getJobById("#00028");

        assertThat(response).isNotNull();
        assertThat(response.getId()).isEqualTo("#00028");
        assertThat(response.getTitle()).isEqualTo("ตรวจล้างแอร์");
    }

    @Test
    @DisplayName("getJobById should throw JobNotFoundException when job does not exist")
    void testGetJobById_NotFound() {
        when(jobRepository.findById("#99999")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> jobService.getJobById("#99999"))
                .isInstanceOf(JobNotFoundException.class)
                .hasMessageContaining("#99999");
    }

    @Test
    @DisplayName("Status transition: PENDING -> IN_PROGRESS should succeed")
    void testTransition_PendingToInProgress_Success() {
        when(jobRepository.findById("#00028")).thenReturn(Optional.of(pendingJob));
        when(jobRepository.saveAndFlush(any(JobEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UpdateJobStatusRequest request = new UpdateJobStatusRequest(JobStatus.IN_PROGRESS, "ช่างเริ่มงานแล้ว");
        JobResponse response = jobService.updateJobStatus("#00028", request);

        assertThat(response.getStatus()).isEqualTo(JobStatus.IN_PROGRESS);
        assertThat(response.getStatusLabel()).isEqualTo("กำลังดำเนินการ");
        assertThat(response.getStatusNote()).isEqualTo("ช่างเริ่มงานแล้ว");
    }

    @Test
    @DisplayName("Status transition: PENDING -> CANCELLED should succeed")
    void testTransition_PendingToCancelled_Success() {
        when(jobRepository.findById("#00028")).thenReturn(Optional.of(pendingJob));
        when(jobRepository.saveAndFlush(any(JobEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UpdateJobStatusRequest request = new UpdateJobStatusRequest(JobStatus.CANCELLED, "ลูกค้ายกเลิกนัด");
        JobResponse response = jobService.updateJobStatus("#00028", request);

        assertThat(response.getStatus()).isEqualTo(JobStatus.CANCELLED);
        assertThat(response.getStatusLabel()).isEqualTo("ยกเลิก");
    }

    @Test
    @DisplayName("Status transition: IN_PROGRESS -> COMPLETED should succeed")
    void testTransition_InProgressToCompleted_Success() {
        when(jobRepository.findById("#00026")).thenReturn(Optional.of(inProgressJob));
        when(jobRepository.saveAndFlush(any(JobEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UpdateJobStatusRequest request = new UpdateJobStatusRequest(JobStatus.COMPLETED, "ติดตั้งเสร็จสมบูรณ์");
        JobResponse response = jobService.updateJobStatus("#00026", request);

        assertThat(response.getStatus()).isEqualTo(JobStatus.COMPLETED);
        assertThat(response.getStatusLabel()).isEqualTo("เสร็จสิ้น");
    }

    @Test
    @DisplayName("Illegal transition: PENDING -> COMPLETED should throw InvalidStatusTransitionException")
    void testTransition_PendingToCompleted_ThrowsException() {
        when(jobRepository.findById("#00028")).thenReturn(Optional.of(pendingJob));

        UpdateJobStatusRequest request = new UpdateJobStatusRequest(JobStatus.COMPLETED, "พยายามข้ามขั้นตอน");

        assertThatThrownBy(() -> jobService.updateJobStatus("#00028", request))
                .isInstanceOf(InvalidStatusTransitionException.class)
                .hasMessageContaining("Cannot transition job");

        verify(jobRepository, never()).save(any(JobEntity.class));
    }

    @Test
    @DisplayName("Terminal status: COMPLETED job cannot be transitioned to any other status")
    void testTransition_CompletedJobIsTerminal_ThrowsException() {
        when(jobRepository.findById("#00025")).thenReturn(Optional.of(completedJob));

        UpdateJobStatusRequest request = new UpdateJobStatusRequest(JobStatus.IN_PROGRESS, "พยายามเปิดงานใหม่");

        assertThatThrownBy(() -> jobService.updateJobStatus("#00025", request))
                .isInstanceOf(InvalidStatusTransitionException.class);

        verify(jobRepository, never()).save(any(JobEntity.class));
    }

    @Test
    @DisplayName("Optimistic lock version mismatch should throw OptimisticLockingFailureException")
    void testOptimisticLock_VersionMismatch_ThrowsException() {
        when(jobRepository.findById("#00028")).thenReturn(Optional.of(pendingJob));

        // pendingJob has version 0, but request sends version 99
        UpdateJobStatusRequest request = new UpdateJobStatusRequest(JobStatus.IN_PROGRESS, "note", 99L);

        assertThatThrownBy(() -> jobService.updateJobStatus("#00028", request))
                .isInstanceOf(OptimisticLockingFailureException.class)
                .hasMessageContaining("version conflict");

        verify(jobRepository, never()).save(any(JobEntity.class));
    }

    @Test
    @DisplayName("getStatistics should aggregate counts accurately")
    void testGetStatistics() {
        when(jobRepository.count()).thenReturn(24L);
        when(jobRepository.countByStatus(JobStatus.PENDING)).thenReturn(8L);
        when(jobRepository.countByStatus(JobStatus.IN_PROGRESS)).thenReturn(10L);
        when(jobRepository.countByStatus(JobStatus.COMPLETED)).thenReturn(6L);
        when(jobRepository.countByStatus(JobStatus.CANCELLED)).thenReturn(0L);

        JobStatisticsResponse stats = jobService.getStatistics();

        assertThat(stats.getTotal()).isEqualTo(24L);
        assertThat(stats.getPending()).isEqualTo(8L);
        assertThat(stats.getInProgress()).isEqualTo(10L);
        assertThat(stats.getCompleted()).isEqualTo(6L);
        assertThat(stats.getCancelled()).isEqualTo(0L);
    }
}
