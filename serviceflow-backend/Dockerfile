# ==============================================================================
# ServiceFlow Backend - Multi-stage Production Dockerfile
# Base: Eclipse Temurin Java 21 (Alpine)
# ==============================================================================

# Stage 1: Build the Application
FROM maven:3.9.6-eclipse-temurin-21-alpine AS builder

WORKDIR /build

# Copy POM first for dependency caching
COPY pom.xml ./

# Download dependencies (offline cache layer)
RUN mvn dependency:go-offline -B || true

# Copy source code and build repackaged fat JAR
COPY src ./src
RUN mvn clean package -DskipTests=true -B

# Extract Spring Boot layers for optimized Docker caching
WORKDIR /build/target
RUN java -Djarmode=layertools -jar serviceflow-backend-*.jar extract

# ------------------------------------------------------------------------------
# Stage 2: Production Minimal Runtime Image
# ------------------------------------------------------------------------------
FROM eclipse-temurin:21-jre-alpine AS runner

# Install curl for healthcheck and tzdata for Bangkok timezone
RUN apk add --no-cache curl tzdata \
    && cp /usr/share/zoneinfo/Asia/Bangkok /etc/localtime \
    && echo "Asia/Bangkok" > /etc/timezone

WORKDIR /app

# Create unprivileged system group and user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Create storage directory with appropriate permissions
RUN mkdir -p /app/storage/photos && chown -R appuser:appgroup /app

# Copy Spring Boot layers from builder stage
COPY --from=builder --chown=appuser:appgroup /build/target/dependencies/ ./
COPY --from=builder --chown=appuser:appgroup /build/target/spring-boot-loader/ ./
COPY --from=builder --chown=appuser:appgroup /build/target/snapshot-dependencies/ ./
COPY --from=builder --chown=appuser:appgroup /build/target/application/ ./

# Switch to unprivileged user
USER appuser:appgroup

# Environment defaults (overridden at runtime by orchestrator / docker compose)
ENV SPRING_PROFILES_ACTIVE=prod \
    SERVER_PORT=8080 \
    JAVA_OPTS="-XX:+UseG1GC -XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError"

EXPOSE 8080

# Health Check via Spring Boot Actuator
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]
