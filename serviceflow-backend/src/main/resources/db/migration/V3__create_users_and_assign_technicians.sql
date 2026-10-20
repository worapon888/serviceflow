-- V3: Create Users, Roles, and Link Jobs to Assigned Technician Foreign Key

-- 1. Create Users Table
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_user_role CHECK (role IN ('ADMIN', 'DISPATCHER', 'TECHNICIAN'))
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- 2. Seed Baseline Users for Local Development & Technicians
-- Passwords will also be safely bootstrapped / managed via SecurityDataInitializer & Environment Variables
INSERT INTO users (username, email, password, full_name, role, active)
VALUES
('admin', 'admin@serviceflow.com', '$2a$10$eE61FwI87/W675XqTqDdQ.90y7fP042c1vFq83UjS6m2rA/7oB5Wq', 'ผู้ดูแลระบบ', 'ADMIN', TRUE),
('dispatcher', 'dispatcher@serviceflow.com', '$2a$10$eE61FwI87/W675XqTqDdQ.90y7fP042c1vFq83UjS6m2rA/7oB5Wq', 'สมหญิง จัดการดี', 'DISPATCHER', TRUE),
('technician', 'technician@serviceflow.com', '$2a$10$eE61FwI87/W675XqTqDdQ.90y7fP042c1vFq83UjS6m2rA/7oB5Wq', 'สมชาย ใจดี', 'TECHNICIAN', TRUE),
('technician2', 'technician2@serviceflow.com', '$2a$10$eE61FwI87/W675XqTqDdQ.90y7fP042c1vFq83UjS6m2rA/7oB5Wq', 'วิชัย เก่งกล้า', 'TECHNICIAN', TRUE)
ON CONFLICT (username) DO NOTHING;

-- 3. Add Foreign Key relationship for Assigned Technician in Jobs Table
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS assigned_technician_id BIGINT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_jobs_assigned_technician'
    ) THEN
        ALTER TABLE jobs
            ADD CONSTRAINT fk_jobs_assigned_technician
            FOREIGN KEY (assigned_technician_id)
            REFERENCES users(id)
            ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_jobs_assigned_technician ON jobs(assigned_technician_id);

-- 4. Preserve existing data and link existing jobs to 'สมชาย ใจดี'
UPDATE jobs
SET assigned_technician_id = (SELECT id FROM users WHERE full_name = jobs.technician LIMIT 1)
WHERE assigned_technician_id IS NULL;
