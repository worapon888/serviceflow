-- Sequence for generating thread-safe, non-duplicate Job IDs (e.g. #00029, #00030)
CREATE SEQUENCE IF NOT EXISTS job_id_seq START WITH 29 INCREMENT BY 1;

-- Jobs Table
CREATE TABLE IF NOT EXISTS jobs (
    id VARCHAR(32) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    client VARCHAR(255) NOT NULL,
    appointment_date VARCHAR(100) NOT NULL,
    appointment_time VARCHAR(50) NOT NULL,
    location VARCHAR(500) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    priority VARCHAR(50) NOT NULL DEFAULT 'Medium',
    job_type VARCHAR(100) NOT NULL DEFAULT 'ซ่อมบำรุง',
    description TEXT,
    technician VARCHAR(255) NOT NULL DEFAULT 'สมชาย ใจดี',
    status_note TEXT DEFAULT '',
    version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_job_status CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT chk_job_priority CHECK (priority IN ('Low', 'Medium', 'High'))
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_client ON jobs(client);
CREATE INDEX IF NOT EXISTS idx_jobs_created_at ON jobs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_title ON jobs(title);

-- Job Photos Table (Ready for Future Photo Management)
CREATE TABLE IF NOT EXISTS job_photos (
    id VARCHAR(64) PRIMARY KEY,
    job_id VARCHAR(32) NOT NULL,
    image_path VARCHAR(1000) NOT NULL,
    photo_type VARCHAR(50) NOT NULL,
    note TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_job_photos_job FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_job_photos_job_id ON job_photos(job_id);
