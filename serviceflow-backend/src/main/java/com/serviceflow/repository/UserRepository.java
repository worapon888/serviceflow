package com.serviceflow.repository;

import com.serviceflow.entity.Role;
import com.serviceflow.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<UserEntity, Long> {

    Optional<UserEntity> findByUsername(String username);

    Optional<UserEntity> findByEmail(String email);

    @Query("SELECT u FROM UserEntity u WHERE LOWER(u.username) = LOWER(:identifier) OR LOWER(u.email) = LOWER(:identifier)")
    Optional<UserEntity> findByUsernameOrEmailIgnoreCase(@Param("identifier") String identifier);

    Optional<UserEntity> findByFullName(String fullName);

    List<UserEntity> findByRoleAndActiveTrue(Role role);

    boolean existsByUsername(String username);

    boolean existsByEmail(String email);
}
