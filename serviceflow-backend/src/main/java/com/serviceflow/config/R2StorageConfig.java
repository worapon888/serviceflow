package com.serviceflow.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;

import java.net.URI;

@Configuration
@ConditionalOnProperty(name = "serviceflow.storage.type", havingValue = "r2")
public class R2StorageConfig {

    private static final Logger log = LoggerFactory.getLogger(R2StorageConfig.class);

    @Value("${serviceflow.storage.r2.endpoint:}")
    private String endpoint;

    @Value("${serviceflow.storage.r2.access-key-id:}")
    private String accessKeyId;

    @Value("${serviceflow.storage.r2.secret-access-key:}")
    private String secretAccessKey;

    @Bean
    public S3Client s3Client() {
        log.info("Configuring S3Client for Cloudflare R2: endpoint={}", endpoint);

        if (endpoint == null || endpoint.isBlank()) {
            throw new IllegalStateException("Cloudflare R2 endpoint must be specified when storage type is 'r2'");
        }

        AwsBasicCredentials credentials = AwsBasicCredentials.create(accessKeyId, secretAccessKey);

        return S3Client.builder()
                .endpointOverride(URI.create(endpoint))
                .credentialsProvider(StaticCredentialsProvider.create(credentials))
                .region(Region.of("auto")) // Cloudflare R2 uses 'auto' region
                .serviceConfiguration(S3Configuration.builder()
                        .pathStyleAccessEnabled(true)
                        .build())
                .build();
    }
}
