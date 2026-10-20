package com.serviceflow.config;

import com.serviceflow.entity.JobEntity;
import com.serviceflow.entity.Role;
import com.serviceflow.entity.UserEntity;
import com.serviceflow.repository.JobRepository;
import com.serviceflow.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Component
public class SecurityDataInitializer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(SecurityDataInitializer.class);

    private final UserRepository userRepository;
    private final JobRepository jobRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${serviceflow.security.bootstrap-admin.enabled:true}")
    private boolean bootstrapEnabled;

    @Value("${serviceflow.security.bootstrap-admin.username:admin}")
    private String adminUsername;

    @Value("${serviceflow.security.bootstrap-admin.email:admin@serviceflow.com}")
    private String adminEmail;

    @Value("${serviceflow.security.bootstrap-admin.password:Admin@123456}")
    private String adminPassword;

    @Value("${serviceflow.security.bootstrap-admin.full-name:ผู้ดูแลระบบ}")
    private String adminFullName;

    @Value("${serviceflow.security.staging.dispatcher-password:}")
    private String stagingDispatcherPassword;

    @Value("${serviceflow.security.staging.technician-password:}")
    private String stagingTechnicianPassword;

    private final org.springframework.core.env.Environment environment;

    public SecurityDataInitializer(
            UserRepository userRepository,
            JobRepository jobRepository,
            PasswordEncoder passwordEncoder,
            org.springframework.core.env.Environment environment
    ) {
        this.userRepository = userRepository;
        this.jobRepository = jobRepository;
        this.passwordEncoder = passwordEncoder;
        this.environment = environment;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (!bootstrapEnabled) {
            log.info("Security bootstrap is disabled.");
            return;
        }

        boolean isDevOrTest = environment.matchesProfiles("dev", "test", "local", "default");

        if (isDevOrTest) {
            // =========================================================================
            // Local Development / Test: Ensure default test accounts are seeded
            // =========================================================================
            // 1. Ensure initial ADMIN user exists. DO NOT reset password if already exists.
            userRepository.findByUsername(adminUsername)
                    .or(() -> userRepository.findByEmail(adminEmail))
                    .ifPresentOrElse(
                            admin -> log.debug("ADMIN user already exists: username={}", adminUsername),
                            () -> {
                                if (adminPassword == null || adminPassword.isBlank()) {
                                    log.warn("Initial admin password is empty; skipping admin bootstrap.");
                                    return;
                                }
                                UserEntity admin = new UserEntity(
                                        adminUsername,
                                        adminEmail,
                                        passwordEncoder.encode(adminPassword),
                                        adminFullName,
                                        Role.ADMIN
                                );
                                userRepository.save(admin);
                                log.info("Bootstrapped initial ADMIN user: username={}", adminUsername);
                            }
                    );

            // 2. Ensure default DISPATCHER user exists (do not overwrite password)
            if (userRepository.findByUsername("dispatcher").isEmpty()) {
                UserEntity dispatcher = new UserEntity(
                        "dispatcher",
                        "dispatcher@serviceflow.com",
                        passwordEncoder.encode("Dispatcher@123"),
                        "สมหญิง จัดการดี",
                        Role.DISPATCHER
                );
                userRepository.save(dispatcher);
                log.info("Bootstrapped default DISPATCHER user: username=dispatcher");
            }

            // 3. Ensure primary TECHNICIAN user ('สมชาย ใจดี') exists (do not overwrite password)
            UserEntity primaryTech = userRepository.findByFullName("สมชาย ใจดี")
                    .or(() -> userRepository.findByUsername("technician"))
                    .orElseGet(() -> {
                        UserEntity tech = new UserEntity(
                                "technician",
                                "technician@serviceflow.com",
                                passwordEncoder.encode("Technician@123"),
                                "สมชาย ใจดี",
                                Role.TECHNICIAN
                        );
                        UserEntity saved = userRepository.save(tech);
                        log.info("Bootstrapped default TECHNICIAN user: username=technician ('สมชาย ใจดี')");
                        return saved;
                    });

            // 4. Ensure secondary TECHNICIAN user ('วิชัย เก่งกล้า') exists (do not overwrite password)
            userRepository.findByUsername("technician2")
                    .or(() -> userRepository.findByFullName("วิชัย เก่งกล้า"))
                    .orElseGet(() -> {
                        UserEntity tech2 = new UserEntity(
                                "technician2",
                                "technician2@serviceflow.com",
                                passwordEncoder.encode("Technician@123"),
                                "วิชัย เก่งกล้า",
                                Role.TECHNICIAN
                        );
                        UserEntity saved = userRepository.save(tech2);
                        log.info("Bootstrapped secondary TECHNICIAN user: username=technician2 ('วิชัย เก่งกล้า')");
                        return saved;
                    });

            // 5. Link existing jobs with NULL assigned_technician to the primary technician
            List<JobEntity> unassignedJobs = jobRepository.findAll().stream()
                    .filter(j -> j.getAssignedTechnician() == null)
                    .toList();

            if (!unassignedJobs.isEmpty()) {
                for (JobEntity job : unassignedJobs) {
                    job.setAssignedTechnician(primaryTech);
                    jobRepository.save(job);
                }
                log.info("Migrated and linked {} unassigned jobs to technician '{}'", unassignedJobs.size(), primaryTech.getFullName());
            }
        } else {
            // =========================================================================
            // Staging & Production Hardened Security Guard:
            // Prohibit all guessable default passwords (Admin@123456, Dispatcher@123, Technician@123).
            // Passwords MUST be provided via secure environment variables or accounts are deactivated.
            // =========================================================================

            // 1. ADMIN Account:
            userRepository.findByUsername(adminUsername)
                    .or(() -> userRepository.findByEmail(adminEmail))
                    .ifPresentOrElse(
                            admin -> {
                                if (adminPassword != null && !adminPassword.isBlank() && !"Admin@123456".equals(adminPassword)) {
                                    admin.setPassword(passwordEncoder.encode(adminPassword));
                                    admin.setActive(true);
                                    userRepository.save(admin);
                                    log.info("Securely configured ADMIN password from environment configuration.");
                                } else {
                                    admin.setActive(false);
                                    userRepository.save(admin);
                                    log.warn("SECURITY ALERT: ADMIN account deactivated on non-dev profile because ADMIN_PASSWORD was empty or still default.");
                                }
                            },
                            () -> {
                                if (adminPassword != null && !adminPassword.isBlank() && !"Admin@123456".equals(adminPassword)) {
                                    UserEntity admin = new UserEntity(
                                            adminUsername,
                                            adminEmail,
                                            passwordEncoder.encode(adminPassword),
                                            adminFullName,
                                            Role.ADMIN
                                    );
                                    userRepository.save(admin);
                                    log.info("Bootstrapped initial ADMIN user with secure password.");
                                } else {
                                    log.error("CRITICAL SECURITY ERROR: ADMIN_PASSWORD environment variable must be set on Staging/Production!");
                                }
                            }
                    );

            // 2. DISPATCHER Account:
            userRepository.findByUsername("dispatcher").ifPresent(dispatcher -> {
                if (stagingDispatcherPassword != null && !stagingDispatcherPassword.isBlank() && !"Dispatcher@123".equals(stagingDispatcherPassword)) {
                    dispatcher.setPassword(passwordEncoder.encode(stagingDispatcherPassword));
                    dispatcher.setActive(true);
                    userRepository.save(dispatcher);
                    log.info("Securely configured DISPATCHER password from DISPATCHER_PASSWORD environment variable.");
                } else {
                    dispatcher.setActive(false);
                    userRepository.save(dispatcher);
                    log.warn("SECURITY ALERT: DISPATCHER test account deactivated on non-dev profile because DISPATCHER_PASSWORD was empty or still default.");
                }
            });

            // 3. TECHNICIAN Accounts:
            userRepository.findByUsername("technician").ifPresent(tech -> {
                if (stagingTechnicianPassword != null && !stagingTechnicianPassword.isBlank() && !"Technician@123".equals(stagingTechnicianPassword)) {
                    tech.setPassword(passwordEncoder.encode(stagingTechnicianPassword));
                    tech.setActive(true);
                    userRepository.save(tech);
                    log.info("Securely configured TECHNICIAN password from TECHNICIAN_PASSWORD environment variable.");
                } else {
                    tech.setActive(false);
                    userRepository.save(tech);
                    log.warn("SECURITY ALERT: TECHNICIAN test account deactivated on non-dev profile because TECHNICIAN_PASSWORD was empty or still default.");
                }
            });

            userRepository.findByUsername("technician2").ifPresent(tech2 -> {
                if (stagingTechnicianPassword != null && !stagingTechnicianPassword.isBlank() && !"Technician@123".equals(stagingTechnicianPassword)) {
                    tech2.setPassword(passwordEncoder.encode(stagingTechnicianPassword));
                    tech2.setActive(true);
                    userRepository.save(tech2);
                } else {
                    tech2.setActive(false);
                    userRepository.save(tech2);
                }
            });

            // Ensure technician relationship is linked if technician exists
            userRepository.findByUsername("technician").ifPresent(primaryTech -> {
                List<JobEntity> unassignedJobs = jobRepository.findAll().stream()
                        .filter(j -> j.getAssignedTechnician() == null)
                        .toList();
                if (!unassignedJobs.isEmpty()) {
                    for (JobEntity job : unassignedJobs) {
                        job.setAssignedTechnician(primaryTech);
                        jobRepository.save(job);
                    }
                }
            });
        }
    }
}
