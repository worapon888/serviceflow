package com.serviceflow.service.impl;

import com.serviceflow.dto.request.CreateJobRequest;
import com.serviceflow.dto.request.UpdateJobStatusRequest;
import com.serviceflow.dto.response.JobResponse;
import com.serviceflow.dto.response.JobStatisticsResponse;
import com.serviceflow.dto.response.PageResponse;
import com.serviceflow.entity.JobEntity;
import com.serviceflow.entity.JobStatus;
import com.serviceflow.entity.Role;
import com.serviceflow.entity.UserEntity;
import com.serviceflow.exception.DuplicateJobException;
import com.serviceflow.exception.InvalidStatusTransitionException;
import com.serviceflow.exception.JobNotFoundException;
import com.serviceflow.mapper.JobMapper;
import com.serviceflow.repository.JobRepository;
import com.serviceflow.repository.UserRepository;
import com.serviceflow.security.SecurityUtils;
import com.serviceflow.security.UserPrincipal;
import com.serviceflow.service.JobService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class JobServiceImpl implements JobService {

    private static final Logger log = LoggerFactory.getLogger(JobServiceImpl.class);

    private final JobRepository jobRepository;
    private final JobMapper jobMapper;
    private final UserRepository userRepository;

    public JobServiceImpl(JobRepository jobRepository, JobMapper jobMapper, UserRepository userRepository) {
        this.jobRepository = jobRepository;
        this.jobMapper = jobMapper;
        this.userRepository = userRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<JobResponse> getJobs(int page, int size, String sortBy, String sortDir, JobStatus status, String search) {
        // Enforce safe bounds for pagination
        int validPage = Math.max(page, 0);
        int validSize = (size <= 0 || size > 100) ? 10 : size;

        Sort.Direction direction = "asc".equalsIgnoreCase(sortDir) ? Sort.Direction.ASC : Sort.Direction.DESC;
        String sortProperty = (sortBy == null || sortBy.isBlank()) ? "createdAt" : sortBy;
        Pageable pageable = PageRequest.of(validPage, validSize, Sort.by(direction, sortProperty));

        Specification<JobEntity> spec = Specification.where(null);

        // Service Layer Security: If current user is TECHNICIAN, only return their assigned jobs
        Optional<UserPrincipal> currentUser = SecurityUtils.getCurrentUser();
        if (currentUser.isPresent() && currentUser.get().getRole() == Role.TECHNICIAN) {
            Long technicianId = currentUser.get().getId();
            spec = spec.and((root, query, cb) -> cb.equal(root.get("assignedTechnician").get("id"), technicianId));
        }

        if (status != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), status));
        }

        if (search != null && !search.trim().isEmpty()) {
            String pattern = "%" + search.trim().toLowerCase() + "%";
            spec = spec.and((root, query, cb) -> cb.or(
                    cb.like(cb.lower(root.get("id")), pattern),
                    cb.like(cb.lower(root.get("title")), pattern),
                    cb.like(cb.lower(root.get("client")), pattern)
            ));
        }

        Page<JobEntity> entityPage = jobRepository.findAll(spec, pageable);
        Page<JobResponse> responsePage = entityPage.map(jobMapper::toResponse);

        return new PageResponse<>(responsePage);
    }

    @Override
    @Transactional(readOnly = true)
    public JobResponse getJobById(String id) {
        JobEntity job = jobRepository.findById(id)
                .orElseThrow(() -> new JobNotFoundException(id));

        // Service Layer Security: Technician can only view their own assigned jobs
        checkTechnicianOwnership(job, "view");

        return jobMapper.toResponse(job);
    }

    @Override
    @Transactional
    public JobResponse createJob(CreateJobRequest request) {
        // Service Layer Security: Only ADMIN and DISPATCHER can create jobs
        Optional<UserPrincipal> currentUser = SecurityUtils.getCurrentUser();
        if (currentUser.isPresent() && currentUser.get().getRole() == Role.TECHNICIAN) {
            throw new AccessDeniedException("Access Denied: Technicians are not authorized to create jobs");
        }

        String targetId;
        if (request.getId() != null && !request.getId().trim().isEmpty()) {
            targetId = request.getId().trim();
            if (jobRepository.existsById(targetId)) {
                throw new DuplicateJobException(targetId);
            }
        } else {
            targetId = generateNextJobId();
        }

        JobEntity entity = jobMapper.toEntity(request, targetId);

        // Assign technician if provided by ID or name
        if (request.getAssignedTechnicianId() != null) {
            UserEntity technician = userRepository.findById(request.getAssignedTechnicianId())
                    .orElseThrow(() -> new IllegalArgumentException("Assigned technician not found with ID: " + request.getAssignedTechnicianId()));
            entity.setAssignedTechnician(technician);
        } else if (request.getTechnician() != null && !request.getTechnician().isBlank()) {
            userRepository.findByFullName(request.getTechnician().trim())
                    .ifPresent(entity::setAssignedTechnician);
        }

        JobEntity saved = jobRepository.save(entity);
        log.info("Created new job with ID: {}", saved.getId());

        return jobMapper.toResponse(saved);
    }

    @Override
    @Transactional
    public JobResponse updateJobStatus(String id, UpdateJobStatusRequest request) {
        JobEntity job = jobRepository.findById(id)
                .orElseThrow(() -> new JobNotFoundException(id));

        // Service Layer Security: Technician can only update their own assigned jobs
        checkTechnicianOwnership(job, "update status of");

        JobStatus currentStatus = job.getStatus();
        JobStatus targetStatus = request.getStatus();

        // 1. Check if job is already in terminal state
        if (currentStatus.isTerminal()) {
            throw new InvalidStatusTransitionException(id, currentStatus, targetStatus);
        }

        // 2. Validate allowed status transition
        if (!currentStatus.canTransitionTo(targetStatus)) {
            throw new InvalidStatusTransitionException(id, currentStatus, targetStatus);
        }

        // 3. Optimistic Locking check (if caller passed expected version)
        if (request.getVersion() != null && !request.getVersion().equals(job.getVersion())) {
            throw new OptimisticLockingFailureException(
                    String.format("Job '%s' version conflict. Expected version %d, but found %d",
                            id, request.getVersion(), job.getVersion())
            );
        }

        // 4. Apply status transition & optional note
        job.setStatus(targetStatus);
        if (request.getNote() != null && !request.getNote().trim().isEmpty()) {
            job.setStatusNote(request.getNote().trim());
        }

        JobEntity saved = jobRepository.saveAndFlush(job);
        log.info("Updated job {} status from {} to {}", id, currentStatus, targetStatus);

        return jobMapper.toResponse(saved);
    }

    @Override
    @Transactional
    public JobResponse assignTechnician(String id, Long technicianId) {
        // Service Layer Security: Only ADMIN and DISPATCHER can assign technicians
        Optional<UserPrincipal> currentUser = SecurityUtils.getCurrentUser();
        if (currentUser.isPresent() && currentUser.get().getRole() == Role.TECHNICIAN) {
            throw new AccessDeniedException("Access Denied: Technicians are not permitted to assign jobs");
        }

        JobEntity job = jobRepository.findById(id)
                .orElseThrow(() -> new JobNotFoundException(id));

        UserEntity technician = userRepository.findById(technicianId)
                .orElseThrow(() -> new IllegalArgumentException("Technician not found with ID: " + technicianId));

        if (technician.getRole() != Role.TECHNICIAN) {
            throw new IllegalArgumentException("User with ID " + technicianId + " is not a TECHNICIAN (role: " + technician.getRole() + ")");
        }

        job.setAssignedTechnician(technician);
        job.setTechnician(technician.getFullName());

        JobEntity saved = jobRepository.saveAndFlush(job);
        log.info("Assigned job {} to technician {} (ID: {})", id, technician.getFullName(), technicianId);

        return jobMapper.toResponse(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public JobStatisticsResponse getStatistics() {
        Optional<UserPrincipal> currentUser = SecurityUtils.getCurrentUser();
        if (currentUser.isPresent() && currentUser.get().getRole() == Role.TECHNICIAN) {
            Long techId = currentUser.get().getId();
            long total = jobRepository.countByAssignedTechnicianId(techId);
            long pending = jobRepository.countByAssignedTechnicianIdAndStatus(techId, JobStatus.PENDING);
            long inProgress = jobRepository.countByAssignedTechnicianIdAndStatus(techId, JobStatus.IN_PROGRESS);
            long completed = jobRepository.countByAssignedTechnicianIdAndStatus(techId, JobStatus.COMPLETED);
            long cancelled = jobRepository.countByAssignedTechnicianIdAndStatus(techId, JobStatus.CANCELLED);
            return new JobStatisticsResponse(total, pending, inProgress, completed, cancelled);
        }

        long total = jobRepository.count();
        long pending = jobRepository.countByStatus(JobStatus.PENDING);
        long inProgress = jobRepository.countByStatus(JobStatus.IN_PROGRESS);
        long completed = jobRepository.countByStatus(JobStatus.COMPLETED);
        long cancelled = jobRepository.countByStatus(JobStatus.CANCELLED);

        return new JobStatisticsResponse(total, pending, inProgress, completed, cancelled);
    }

    private void checkTechnicianOwnership(JobEntity job, String action) {
        Optional<UserPrincipal> currentUser = SecurityUtils.getCurrentUser();
        if (currentUser.isPresent() && currentUser.get().getRole() == Role.TECHNICIAN) {
            Long currentUserId = currentUser.get().getId();
            if (job.getAssignedTechnician() == null || !currentUserId.equals(job.getAssignedTechnician().getId())) {
                log.warn("Technician user {} attempted unauthorized {} job {}", currentUserId, action, job.getId());
                throw new AccessDeniedException("Access Denied: You are not authorized to " + action + " jobs assigned to other technicians");
            }
        }
    }

    /**
     * Generates a thread-safe, atomic job ID (e.g. #00029) via DB sequence or fallback.
     */
    private synchronized String generateNextJobId() {
        try {
            Optional<Long> nextSeq = jobRepository.getNextSequenceValue();
            if (nextSeq.isPresent()) {
                return String.format("#%05d", nextSeq.get());
            }
        } catch (Exception ex) {
            log.debug("Database sequence query failed (falling back to max ID parsing): {}", ex.getMessage());
        }

        long maxNumber = jobRepository.findAll().stream()
                .map(JobEntity::getId)
                .map(id -> id.replaceAll("\\D+", ""))
                .filter(digits -> !digits.isEmpty())
                .mapToLong(Long::parseLong)
                .max()
                .orElse(0L);

        return String.format("#%05d", maxNumber + 1);
    }
}
