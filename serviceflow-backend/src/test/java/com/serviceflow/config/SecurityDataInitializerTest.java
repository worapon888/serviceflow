package com.serviceflow.config;

import com.serviceflow.entity.Role;
import com.serviceflow.entity.UserEntity;
import com.serviceflow.repository.JobRepository;
import com.serviceflow.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.core.env.Environment;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Collections;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SecurityDataInitializerTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private JobRepository jobRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private Environment environment;

    private SecurityDataInitializer initializer;

    @BeforeEach
    void setUp() {
        initializer = new SecurityDataInitializer(
                userRepository,
                jobRepository,
                passwordEncoder,
                environment
        );
        ReflectionTestUtils.setField(initializer, "bootstrapEnabled", true);
        ReflectionTestUtils.setField(initializer, "adminUsername", "admin");
        ReflectionTestUtils.setField(initializer, "adminEmail", "admin@serviceflow.com");
        ReflectionTestUtils.setField(initializer, "adminFullName", "ผู้ดูแลระบบ");
    }

    @Test
    @DisplayName("On Staging profile, default accounts are DEACTIVATED if default/missing passwords")
    void stagingProfile_deactivatesDefaultAccountsWhenPasswordsAreDefault() {
        when(environment.matchesProfiles("dev", "test", "local", "default")).thenReturn(false);

        UserEntity admin = new UserEntity("admin", "admin@serviceflow.com", "hash", "Admin", Role.ADMIN);
        UserEntity dispatcher = new UserEntity("dispatcher", "disp@sf.com", "hash", "Disp", Role.DISPATCHER);
        UserEntity tech = new UserEntity("technician", "tech@sf.com", "hash", "Tech", Role.TECHNICIAN);

        when(userRepository.findByUsername("admin")).thenReturn(Optional.of(admin));
        when(userRepository.findByUsername("dispatcher")).thenReturn(Optional.of(dispatcher));
        when(userRepository.findByUsername("technician")).thenReturn(Optional.of(tech));
        when(userRepository.findByUsername("technician2")).thenReturn(Optional.empty());
        when(jobRepository.findAll()).thenReturn(Collections.emptyList());

        ReflectionTestUtils.setField(initializer, "adminPassword", "Admin@123456");
        ReflectionTestUtils.setField(initializer, "stagingDispatcherPassword", "");
        ReflectionTestUtils.setField(initializer, "stagingTechnicianPassword", "");

        initializer.run(new DefaultApplicationArguments(new String[0]));

        assertThat(admin.isActive()).isFalse();
        assertThat(dispatcher.isActive()).isFalse();
        assertThat(tech.isActive()).isFalse();
        verify(userRepository, atLeastOnce()).save(admin);
        verify(userRepository, atLeastOnce()).save(dispatcher);
        verify(userRepository, atLeastOnce()).save(tech);
    }

    @Test
    @DisplayName("On Staging profile, accounts are activated and updated when secure environment passwords provided")
    void stagingProfile_activatesAndUpdatesWhenSecurePasswordsProvided() {
        when(environment.matchesProfiles("dev", "test", "local", "default")).thenReturn(false);

        UserEntity admin = new UserEntity("admin", "admin@serviceflow.com", "old-hash", "Admin", Role.ADMIN);
        UserEntity dispatcher = new UserEntity("dispatcher", "disp@sf.com", "old-hash", "Disp", Role.DISPATCHER);
        UserEntity tech = new UserEntity("technician", "tech@sf.com", "old-hash", "Tech", Role.TECHNICIAN);

        when(userRepository.findByUsername("admin")).thenReturn(Optional.of(admin));
        when(userRepository.findByUsername("dispatcher")).thenReturn(Optional.of(dispatcher));
        when(userRepository.findByUsername("technician")).thenReturn(Optional.of(tech));
        when(userRepository.findByUsername("technician2")).thenReturn(Optional.empty());
        when(jobRepository.findAll()).thenReturn(Collections.emptyList());

        when(passwordEncoder.encode("StagingAdmin#9999!")).thenReturn("encoded-admin-secret");
        when(passwordEncoder.encode("StagingDispatcher#8888!")).thenReturn("encoded-dispatcher-secret");
        when(passwordEncoder.encode("StagingTech#7777!")).thenReturn("encoded-tech-secret");

        ReflectionTestUtils.setField(initializer, "adminPassword", "StagingAdmin#9999!");
        ReflectionTestUtils.setField(initializer, "stagingDispatcherPassword", "StagingDispatcher#8888!");
        ReflectionTestUtils.setField(initializer, "stagingTechnicianPassword", "StagingTech#7777!");

        initializer.run(new DefaultApplicationArguments(new String[0]));

        assertThat(admin.isActive()).isTrue();
        assertThat(admin.getPassword()).isEqualTo("encoded-admin-secret");

        assertThat(dispatcher.isActive()).isTrue();
        assertThat(dispatcher.getPassword()).isEqualTo("encoded-dispatcher-secret");

        assertThat(tech.isActive()).isTrue();
        assertThat(tech.getPassword()).isEqualTo("encoded-tech-secret");
    }

    @Test
    @DisplayName("On Dev profile, default test accounts are kept active")
    void devProfile_keepsDefaultAccountsActive() {
        when(environment.matchesProfiles("dev", "test", "local", "default")).thenReturn(true);

        UserEntity admin = new UserEntity("admin", "admin@serviceflow.com", "hash", "Admin", Role.ADMIN);
        when(userRepository.findByUsername("admin")).thenReturn(Optional.of(admin));
        when(userRepository.findByUsername("dispatcher")).thenReturn(Optional.empty());
        when(userRepository.findByFullName("สมชาย ใจดี")).thenReturn(Optional.empty());
        when(userRepository.findByUsername("technician")).thenReturn(Optional.empty());
        when(userRepository.findByUsername("technician2")).thenReturn(Optional.empty());
        when(userRepository.findByFullName("วิชัย เก่งกล้า")).thenReturn(Optional.empty());

        when(passwordEncoder.encode(anyString())).thenReturn("bcrypt-hash");
        when(userRepository.save(any(UserEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ReflectionTestUtils.setField(initializer, "adminPassword", "Admin@123456");

        initializer.run(new DefaultApplicationArguments(new String[0]));

        assertThat(admin.isActive()).isTrue();
        verify(userRepository, atLeast(1)).save(argThat(user -> "dispatcher".equals(user.getUsername()) && user.isActive()));
        verify(userRepository, atLeast(1)).save(argThat(user -> "technician".equals(user.getUsername()) && user.isActive()));
    }
}
