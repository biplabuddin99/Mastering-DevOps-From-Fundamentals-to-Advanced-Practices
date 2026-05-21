# Database Setup for GitHub Actions

## Overview

When using GitHub Actions for deployment, you need to provide database credentials as secrets. This guide explains how to choose and configure your PostgreSQL database password.

---

## For Fresh EC2 Deployments

If deploying to a **fresh EC2 instance**, GitHub Actions will:
1. Install PostgreSQL automatically
2. Create database user (`bmi_user`) and database (`bmidb`)
3. Use the password you provide in `DB_PASSWORD` secret
4. Run migrations automatically

### Required Secret: `DB_PASSWORD`

Choose a strong password following these guidelines:

**Password Requirements:**
- Minimum 12 characters
- Mix of uppercase and lowercase letters
- Include numbers
- Include special characters (!@#$%^&*)
- Avoid common words or patterns

**Example Strong Passwords:**
```
Bm1Track3r#2025!Secure
P@ssw0rd!PostgreSQL#BMI
HealthApp#DB$2025Secure!
```

### Add to GitHub Secrets

1. Go to GitHub repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `DB_PASSWORD`
4. Value: Your chosen strong password
5. Click **Add secret**

---

## For Existing Deployments

If your application is **already deployed** with a working database:

### Option 1: No Secret Needed (Recommended)

Your database is already configured with a password in the backend `.env` file. GitHub Actions will use the existing database configuration.

**You don't need to add `DB_PASSWORD` secret.**

### Option 2: Add Secret for Consistency

If you want to standardize your secrets, you can optionally add the existing database password:

1. SSH to your EC2 server:
   ```bash
   ssh ubuntu@YOUR_EC2_IP
   ```

2. View your current database password:
   ```bash
   cat ~/single-server-3tier-webapp/backend/.env
   ```

3. Find the line:
   ```
   DATABASE_URL=postgresql://bmi_user:YOUR_PASSWORD@localhost:5432/bmidb
   ```

4. Extract `YOUR_PASSWORD` and add it as `DB_PASSWORD` secret in GitHub

---

## Database Security Best Practices

### 1. Use Environment Variables

✅ **Do:** Store passwords in `.env` files and GitHub Secrets  
❌ **Don't:** Hardcode passwords in source code

### 2. Restrict Access

```bash
# On EC2 server, ensure .env is not readable by others
chmod 600 ~/single-server-3tier-webapp/backend/.env
```

### 3. PostgreSQL Configuration

By default, PostgreSQL is configured to:
- Listen only on `localhost` (not exposed to internet)
- Require password authentication
- Use `md5` encryption for passwords

Verify configuration:
```bash
sudo cat /etc/postgresql/*/main/pg_hba.conf
```

Should see:
```
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
```

### 4. Regular Password Rotation

Change database password periodically:

```bash
# Connect to PostgreSQL
sudo -u postgres psql

# Change password
ALTER USER bmi_user WITH PASSWORD 'new_strong_password';
\q

# Update .env file
nano ~/single-server-3tier-webapp/backend/.env
# Change the password in DATABASE_URL

# Update GitHub secret
# Go to GitHub → Settings → Secrets → DB_PASSWORD → Update

# Restart backend
pm2 restart bmi-backend
```

---

## Database Connection String Format

The application uses this connection string format:

```
postgresql://USERNAME:PASSWORD@HOST:PORT/DATABASE
```

**For this project:**
```
postgresql://bmi_user:YOUR_PASSWORD@localhost:5432/bmidb
```

**Components:**
- `bmi_user` - Database user (created by GitHub Actions)
- `YOUR_PASSWORD` - Password from `DB_PASSWORD` secret
- `localhost` - Database host (same server)
- `5432` - PostgreSQL default port
- `bmidb` - Database name

---

## Troubleshooting

### Issue: "password authentication failed for user bmi_user"

**Solution:**
1. Verify `DB_PASSWORD` secret matches the actual database password
2. Check `.env` file on server: `cat ~/single-server-3tier-webapp/backend/.env`
3. Update password if needed:
   ```bash
   sudo -u postgres psql -c "ALTER USER bmi_user WITH PASSWORD 'correct_password';"
   ```

### Issue: "database bmidb does not exist"

**Solution:**
GitHub Actions will create the database on first deployment. If it failed:

```bash
# Create database manually
sudo -u postgres psql -c "CREATE DATABASE bmidb OWNER bmi_user;"
```

### Issue: "peer authentication failed"

**Solution:**
PostgreSQL is trying to use system user authentication instead of password.

Fix `pg_hba.conf`:
```bash
sudo nano /etc/postgresql/*/main/pg_hba.conf

# Change this line:
# local   all             all                                     peer
# To:
local   all             all                                     md5

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### Issue: Connection string format error

**Correct format:**
```bash
DATABASE_URL=postgresql://bmi_user:password@localhost:5432/bmidb
```

**Common mistakes:**
```bash
# ❌ Missing protocol
DATABASE_URL=bmi_user:password@localhost:5432/bmidb

# ❌ Wrong protocol
DATABASE_URL=postgres://bmi_user:password@localhost:5432/bmidb

# ❌ Special characters not encoded
# If password has special characters like @, #, encode them:
# @ = %40, # = %23, $ = %24, etc.
```

---

## Verify Database Setup

After deployment, verify database is working:

```bash
# SSH to EC2
ssh ubuntu@YOUR_EC2_IP

# Test database connection
psql -h localhost -U bmi_user -d bmidb -c "\dt"
# Enter password when prompted

# Check tables exist
psql -h localhost -U bmi_user -d bmidb -c "SELECT COUNT(*) FROM measurements;"

# Test backend can connect
curl http://localhost:3000/health
curl http://localhost:3000/api/measurements
```

---

## Summary

### For Fresh EC2:
✅ Add `DB_PASSWORD` secret to GitHub (required)  
✅ Choose a strong password  
✅ GitHub Actions will setup everything else  

### For Existing Deployments:
✅ `DB_PASSWORD` secret is optional  
✅ Existing database configuration will be used  
✅ Only add secret if you want to standardize  

**Next Steps:** Return to [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) to complete deployment setup.

---

🧑‍💻 **Author**  
**Md. Sarowar Alam**  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: linkedin.com/in/sarowar
