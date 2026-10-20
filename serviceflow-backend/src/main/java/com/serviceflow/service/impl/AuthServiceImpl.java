package com.serviceflow.service.impl;

import com.serviceflow.dto.request.LoginRequest;
import com.serviceflow.dto.response.AuthResponse;
import com.serviceflow.dto.response.UserResponse;
import com.serviceflow.entity.UserEntity;
import com.serviceflow.repository.UserRepository;
import com.serviceflow.security.JwtTokenProvider;
import com.serviceflow.security.SecurityUtils;
import com.serviceflow.security.UserPrincipal;
import com.serviceflow.service.AuthService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthServiceImpl implements AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthServiceImpl.class);

    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider jwtTokenProvider;
    private final UserRepository userRepository;

    public AuthServiceImpl(
            AuthenticationManager authenticationManager,
            JwtTokenProvider jwtTokenProvider,
            UserRepository userRepository
    ) {
        this.authenticationManager = authenticationManager;
        this.jwtTokenProvider = jwtTokenProvider;
        this.userRepository = userRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword())
            );

            UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
            String accessToken = jwtTokenProvider.generateToken(principal);

            UserEntity user = userRepository.findById(principal.getId())
                    .orElseThrow(() -> new UsernameNotFoundException("User not found"));

            log.info("User logged in successfully: username={}, role={}", user.getUsername(), user.getRole());

            return new AuthResponse(
                    accessToken,
                    jwtTokenProvider.getExpirationInSeconds(),
                    UserResponse.fromEntity(user)
            );
        } catch (AuthenticationException ex) {
            log.warn("Login failed for user identifier: {}", request.getUsername());
            throw new BadCredentialsException("Invalid username/email or password");
        }
    }

    @Override
    @Transactional(readOnly = true)
    public UserResponse getCurrentUserProfile() {
        Long userId = SecurityUtils.getCurrentUserId()
                .orElseThrow(() -> new BadCredentialsException("No authenticated user in context"));

        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with id: " + userId));

        return UserResponse.fromEntity(user);
    }
}
