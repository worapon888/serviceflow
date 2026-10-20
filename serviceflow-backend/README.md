# ServiceFlow Backend - Staging & Production Deployment Guide

## 1. Overview
ServiceFlow Backend is built with **Spring Boot 3.3.4 (Java 21)**, **PostgreSQL 16**, and **Spring Security + JWT**. This guide describes the environment configuration, container deployment, database provisioning, and operational procedures for Staging and Production.

---

## 2. Environment Variables Checklist

The production profile (`application-prod.yml`) enforces zero-hardcoded secrets. The following variables must be provided by your container orchestrator (Kubernetes, AWS ECS, Google Cloud Run) or `.env` file:

| Variable | Required? | Example Value | Description |
|:---|:---:|:---|:---|
| `SPRING_PROFILES_ACTIVE` | Yes | `prod` (or `staging`) | Active Spring Boot profile. |
| `SERVER_PORT` | No | `8080` | HTTP listening port (defaults to 8080). |
| `DB_URL` | **Yes** | `jdbc:postgresql://postgres.internal:5432/serviceflow_db?sslmode=require` | PostgreSQL JDBC connection URL with SSL enabled. |
| `DB_USERNAME` | **Yes** | `sf_app_user` | Dedicated PostgreSQL database user (least-privilege). |
| `DB_PASSWORD` | **Yes** | `(Strong secret)` | Database user password. |
| `DB_POOL_MAX_SIZE` | No | `20` | HikariCP maximum pool size. |
| `DB_POOL_MIN_IDLE` | No | `10` | HikariCP minimum idle connections. |
| `JWT_SECRET` | **Yes** | `(>= 32 bytes / 256 bits)` | HMAC-SHA256 signing key. Must be a cryptographically random secret. |
| `JWT_EXPIRATION_MS` | No | `86400000` (24h) | Token validity duration in milliseconds. |
| `JWT_ISSUER` | No | `serviceflow-backend` | Token issuer identifier. |
| `STORAGE_TYPE` | No | `local` or `r2` | Photo storage driver. Defaults to `local`. |
| `PHOTO_STORAGE_DIR` | If local | `/app/storage/photos` | Path to persistent volume for photo storage. |
| `R2_ENDPOINT` | If r2 | `https://<account_id>.r2.cloudflarestorage.com` | Cloudflare R2 S3-compatible API endpoint. |
| `R2_ACCESS_KEY_ID` | If r2 | `(Cloudflare R2 Key ID)` | Cloudflare R2 access key. |
| `R2_SECRET_ACCESS_KEY`| If r2 | `(Cloudflare R2 Secret)` | Cloudflare R2 secret key. |
| `R2_BUCKET_NAME` | If r2 | `serviceflow-photos` | Cloudflare R2 bucket name. |
| `ADMIN_BOOTSTRAP_ENABLED`| No | `false` | Must be `false` in production. Enable only for first-time manual bootstrap. |
| `ADMIN_PASSWORD` | If bootstrap | `(Strong password)` | Initial bootstrap admin password. Default dev password is strictly blocked. |

---

## 3. Container Build & Run

### 3.1 Build Multi-Stage Docker Image
```bash
docker build -t serviceflow-backend:1.0.0 .
```

### 3.2 Run Container (Staging/Production Simulation)
```bash
docker run -d \
  --name serviceflow-backend \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e DB_URL="jdbc:postgresql://host.docker.internal:5432/serviceflow_db?sslmode=prefer" \
  -e DB_USERNAME="postgres" \
  -e DB_PASSWORD="your_strong_db_password" \
  -e JWT_SECRET="ProductionSuperSecretKeyAtLeast256BitsLongRandomHash1234567890!" \
  -e STORAGE_TYPE="local" \
  -v serviceflow_photos:/app/storage/photos \
  serviceflow-backend:1.0.0
```

### 3.3 Health Check Verification
```bash
curl -I http://localhost:8080/actuator/health
# Expected output: HTTP/1.1 200 OK
# Body: {"status":"UP"}
```

---

## 4. PostgreSQL Staging / Production Preparation

### 4.1 SSL/TLS Connection
Ensure the production database requires SSL. Append `?sslmode=require` or `?sslmode=verify-full` to the `DB_URL` string.

### 4.2 Flyway Migration Forward-Only Policy
- All database schema updates must be committed as versioned migrations in `src/main/resources/db/migration` (`V5__...sql`, `V6__...sql`).
- **Never edit or delete applied migrations** (`V1` to `V4`) to prevent checksum validation failures.
- If a migration fails in Staging or Production, inspect `flyway_schema_history`, resolve the root cause via a corrective forward migration (e.g., `V5_1__...sql`), and run `flyway repair` if necessary.

### 4.3 Database Backup Strategy
- **Nightly Logical Dump:**
  ```bash
  pg_dump -Fc -U sf_app_user -h postgres.internal -d serviceflow_db > serviceflow_db_$(date +%Y%m%d_%H%M%S).dump
  ```
- **Point-In-Time Recovery (PITR):** Enable WAL archiving on the managed cloud database (e.g. AWS RDS or GCP Cloud SQL) with continuous 7-day retention.

---

## 5. Photo Storage: Cloudflare R2 Transition

When migrating from local disk to Cloudflare R2:
1. Create a private bucket in Cloudflare R2 (e.g. `serviceflow-photos`). Ensure **Public Access is DISABLED**.
2. Generate R2 S3-compatible API tokens with `Object Read & Write` permissions.
3. Configure environment variables:
   ```bash
   STORAGE_TYPE=r2
   R2_ENDPOINT=https://<account_id>.r2.cloudflarestorage.com
   R2_ACCESS_KEY_ID=<access_key_id>
   R2_SECRET_ACCESS_KEY=<secret_access_key>
   R2_BUCKET_NAME=serviceflow-photos
   ```
4. All photo streaming continues through `GET /api/v1/jobs/{jobId}/photos/{photoId}/content`, strictly requiring JWT authentication and validating Technician/Dispatcher permissions before proxying from R2.
