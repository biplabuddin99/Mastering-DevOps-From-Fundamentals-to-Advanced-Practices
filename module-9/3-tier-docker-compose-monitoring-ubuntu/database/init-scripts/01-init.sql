-- BMI Health Tracker Database Initialization
-- Description: Create database and grant privileges
-- This runs automatically when PostgreSQL container starts for the first time
-- NOTE: User is already created by POSTGRES_USER env var in docker-compose

-- Create database if not exists
SELECT 'CREATE DATABASE bmidb'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'bmidb')\gexec

-- Grant all privileges
GRANT ALL PRIVILEGES ON DATABASE bmidb TO bmi_user;

-- Connect to the database and grant schema privileges
\c bmidb

-- Grant privileges on public schema
GRANT ALL ON SCHEMA public TO bmi_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO bmi_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO bmi_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO bmi_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO bmi_user;

-- Display confirmation
SELECT 'Database initialization completed successfully' AS status;
