package com.serviceflow.repository;

import com.serviceflow.entity.JobPhotoEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface JobPhotoRepository extends JpaRepository<JobPhotoEntity, String> {

    List<JobPhotoEntity> findByJobIdOrderByCreatedAtDesc(String jobId);

    long countByJobId(String jobId);
}
