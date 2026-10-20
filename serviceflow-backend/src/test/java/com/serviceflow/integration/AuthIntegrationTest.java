package com.serviceflow.integration;

import com.serviceflow.dto.request.LoginRequest;
import com.serviceflow.dto.response.ApiResponse;
import com.serviceflow.dto.response.AuthResponse;
import com.serviceflow.dto.response.ErrorResponse;
import com.serviceflow.dto.response.UserResponse;
import com.serviceflow.entity.Role;
import com.serviceflow.security.JwtTokenProvider;
import com.serviceflow.security.UserPrincipal;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class AuthIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    private String authUrl;
    private String jobsUrl;

    @BeforeEach
    void setUp() {
        authUrl = "http://localhost:" + port + "/api/v1/auth";
        jobsUrl = "http://localhost:" + port + "/api/v1/jobs";
    }

    @Test
    @DisplayName("1. Login Success: Authenticate with username and password, returns 200 and valid JWT token")
    void testLogin_Success_WithUsername() {
        LoginRequest request = new LoginRequest("admin", "Admin@123456");

        ResponseEntity<ApiResponse<AuthResponse>> response = restTemplate.exchange(
                authUrl + "/login",
                HttpMethod.POST,
                new HttpEntity<>(request),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isTrue();

        AuthResponse authData = response.getBody().getData();
        assertThat(authData.getAccessToken()).isNotBlank();
        assertThat(authData.getTokenType()).isEqualTo("Bearer");
        assertThat(authData.getExpiresIn()).isGreaterThan(0);
        assertThat(authData.getUser()).isNotNull();
        assertThat(authData.getUser().getUsername()).isEqualTo("admin");
        assertThat(authData.getUser().getRole()).isEqualTo(Role.ADMIN);
    }

    @Test
    @DisplayName("1b. Login Success: Authenticate with email and password")
    void testLogin_Success_WithEmail() {
        LoginRequest request = new LoginRequest("dispatcher@serviceflow.com", "Dispatcher@123");

        ResponseEntity<ApiResponse<AuthResponse>> response = restTemplate.exchange(
                authUrl + "/login",
                HttpMethod.POST,
                new HttpEntity<>(request),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getData().getUser().getRole()).isEqualTo(Role.DISPATCHER);
    }

    @Test
    @DisplayName("2. Login Failure: Incorrect password returns 401 Unauthorized")
    void testLogin_WrongPassword_Returns401() {
        LoginRequest request = new LoginRequest("admin", "WrongPassword123!");

        ResponseEntity<ErrorResponse> response = restTemplate.exchange(
                authUrl + "/login",
                HttpMethod.POST,
                new HttpEntity<>(request),
                ErrorResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getStatus()).isEqualTo(401);
        assertThat(response.getBody().getMessage()).containsIgnoringCase("invalid");
    }

    @Test
    @DisplayName("2b. Login Failure: Non-existent username returns 401 Unauthorized")
    void testLogin_UserNotFound_Returns401() {
        LoginRequest request = new LoginRequest("non_existent_user", "SomePassword123!");

        ResponseEntity<ErrorResponse> response = restTemplate.exchange(
                authUrl + "/login",
                HttpMethod.POST,
                new HttpEntity<>(request),
                ErrorResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    @DisplayName("3. Unauthenticated: Calling protected endpoint without JWT returns 401 Unauthorized")
    void testProtectedEndpoint_MissingJwt_Returns401() {
        ResponseEntity<ErrorResponse> response = restTemplate.exchange(
                authUrl + "/me",
                HttpMethod.GET,
                null,
                ErrorResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getStatus()).isEqualTo(401);
    }

    @Test
    @DisplayName("4. Expired Token: Request with an expired JWT token returns 401 Unauthorized")
    void testProtectedEndpoint_ExpiredJwt_Returns401() {
        // Create an expired token (1 hour in the past)
        String expiredToken = Jwts.builder()
                .subject("admin")
                .issuer("serviceflow-backend")
                .issuedAt(new Date(System.currentTimeMillis() - 7200000))
                .expiration(new Date(System.currentTimeMillis() - 3600000))
                .claim("userId", 1L)
                .claim("role", "ADMIN")
                .signWith(Keys.hmacShaKeyFor("TestSecretForJwtTestingPurposesAtLeast256BitsLong1234567890!".getBytes(StandardCharsets.UTF_8)))
                .compact();

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(expiredToken);

        ResponseEntity<ErrorResponse> response = restTemplate.exchange(
                authUrl + "/me",
                HttpMethod.GET,
                new HttpEntity<>(headers),
                ErrorResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    @DisplayName("5. Tampered Token: Request with a modified JWT token returns 401 Unauthorized")
    void testProtectedEndpoint_TamperedJwt_Returns401() {
        // Sign with a different secret key (tampered / forged)
        String tamperedToken = Jwts.builder()
                .subject("admin")
                .issuer("serviceflow-backend")
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + 3600000))
                .claim("userId", 1L)
                .claim("role", "ADMIN")
                .signWith(Keys.hmacShaKeyFor("CompletelyDifferentForgedSecretKeyMustBe256BitsLong1234567890!".getBytes(StandardCharsets.UTF_8)))
                .compact();

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(tamperedToken);

        ResponseEntity<ErrorResponse> response = restTemplate.exchange(
                authUrl + "/me",
                HttpMethod.GET,
                new HttpEntity<>(headers),
                ErrorResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    @DisplayName("5b. Malformed Token: Corrupted token string returns 401 Unauthorized")
    void testProtectedEndpoint_MalformedJwt_Returns401() {
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer invalid.corrupted.token.value");

        ResponseEntity<ErrorResponse> response = restTemplate.exchange(
                authUrl + "/me",
                HttpMethod.GET,
                new HttpEntity<>(headers),
                ErrorResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    @DisplayName("Profile Verification: Authenticated user can fetch their profile via GET /api/v1/auth/me")
    void testGetProfile_Success() {
        LoginRequest loginReq = new LoginRequest("admin", "Admin@123456");
        ResponseEntity<ApiResponse<AuthResponse>> loginRes = restTemplate.exchange(
                authUrl + "/login",
                HttpMethod.POST,
                new HttpEntity<>(loginReq),
                new ParameterizedTypeReference<>() {}
        );
        String token = loginRes.getBody().getData().getAccessToken();

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);

        ResponseEntity<ApiResponse<UserResponse>> profileRes = restTemplate.exchange(
                authUrl + "/me",
                HttpMethod.GET,
                new HttpEntity<>(headers),
                new ParameterizedTypeReference<>() {}
        );

        assertThat(profileRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(profileRes.getBody()).isNotNull();
        assertThat(profileRes.getBody().getData().getUsername()).isEqualTo("admin");
        assertThat(profileRes.getBody().getData().getEmail()).isEqualTo("admin@serviceflow.com");
        assertThat(profileRes.getBody().getData().getRole()).isEqualTo(Role.ADMIN);
    }
}
