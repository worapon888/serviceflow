package com.serviceflow.controller;

import com.serviceflow.dto.response.ApiResponse;
import com.serviceflow.dto.response.UserResponse;
import com.serviceflow.entity.Role;
import com.serviceflow.repository.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/users")
@Tag(name = "User Management", description = "Endpoints for user queries and role management")
@SecurityRequirement(name = "bearerAuth")
public class UserController {

    private final UserRepository userRepository;

    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/technicians")
    @PreAuthorize("hasAnyRole('ADMIN', 'DISPATCHER')")
    @Operation(summary = "Get Active Technicians", description = "Retrieve list of active technicians for assignment")
    public ResponseEntity<ApiResponse<List<UserResponse>>> getTechnicians() {
        List<UserResponse> technicians = userRepository.findByRoleAndActiveTrue(Role.TECHNICIAN)
                .stream()
                .map(UserResponse::fromEntity)
                .toList();

        return ResponseEntity.ok(ApiResponse.ok("Technicians retrieved successfully", technicians));
    }
}
