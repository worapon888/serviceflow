package com.serviceflow.security;

import com.serviceflow.entity.Role;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;

public final class SecurityUtils {

    private SecurityUtils() {
    }

    public static Optional<UserPrincipal> getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof UserPrincipal principal) {
            return Optional.of(principal);
        }
        return Optional.empty();
    }

    public static Optional<String> getCurrentUsername() {
        return getCurrentUser().map(UserPrincipal::getUsername);
    }

    public static Optional<Long> getCurrentUserId() {
        return getCurrentUser().map(UserPrincipal::getId);
    }

    public static Optional<Role> getCurrentUserRole() {
        return getCurrentUser().map(UserPrincipal::getRole);
    }

    public static boolean hasRole(Role role) {
        return getCurrentUserRole().map(r -> r == role).orElse(false);
    }

    public static boolean isAdmin() {
        return hasRole(Role.ADMIN);
    }

    public static boolean isDispatcher() {
        return hasRole(Role.DISPATCHER);
    }

    public static boolean isTechnician() {
        return hasRole(Role.TECHNICIAN);
    }
}
