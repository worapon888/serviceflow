package com.serviceflow.service;

import com.serviceflow.dto.request.LoginRequest;
import com.serviceflow.dto.response.AuthResponse;
import com.serviceflow.dto.response.UserResponse;

public interface AuthService {

    AuthResponse login(LoginRequest request);

    UserResponse getCurrentUserProfile();
}
