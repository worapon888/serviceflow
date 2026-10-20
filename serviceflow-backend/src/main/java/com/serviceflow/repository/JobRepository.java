package com.serviceflow.repository;

import com.serviceflow.entity.JobEntity;
import com.serviceflow.entity.JobStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface JobRepository extends JpaRepository<JobEntity, String>, JpaSpecificationExecutor<JobEntity> {

    long countByStatus(JobStatus status);

    @Query("SELECT COUNT(j) FROM JobEntity j WHERE j.assignedTechnician.id = :technicianId")
    long countByAssignedTechnicianId(@org.springframework.data.repository.query.Param("technicianId") Long technicianId);

    @Query("SELECT COUNT(j) FROM JobEntity j WHERE j.assignedTechnician.id = :technicianId AND j.status = :status")
    long countByAssignedTechnicianIdAndStatus(@org.springframework.data.repository.query.Param("technicianId") Long technicianId, @org.springframework.data.repository.query.Param("status") JobStatus status);

    @Query(value = "SELECT nextval('job_id_seq')", nativeQuery = true)
    Optional<Long> getNextSequenceValue();
}
