# Contributing to BMI Health Tracker

Thank you for your interest in contributing! This guide will help you safely introduce changes to the project.

---

## Table of Contents

- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Code Standards](#code-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Infrastructure Changes](#infrastructure-changes)
- [Database Migrations](#database-migrations)
- [Security Guidelines](#security-guidelines)

---

## Getting Started

### 1. Fork and Clone

```bash
# Fork repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/terraform-3-tier-basic.git
cd terraform-3-tier-basic

# Add upstream remote
git remote add upstream https://github.com/md-sarowar-alam/terraform-3-tier-basic.git

# Keep your fork updated
git fetch upstream
git merge upstream/main
```

### 2. Create Feature Branch

**Branch naming convention:**
- `feature/<description>` - New features
- `fix/<description>` - Bug fixes
- `docs/<description>` - Documentation updates
- `refactor/<description>` - Code refactoring
- `test/<description>` - Test additions/updates

```bash
git checkout -b feature/add-weight-goal-tracking
```

### 3. Set Up Local Development

Follow the [Local Development](README.md#local-development) section in README.md

---

## Development Environment

### Backend Development

```bash
cd backend

# Install dependencies
npm install

# Run in development mode with auto-reload
npx nodemon src/server.js

# Or add to package.json:
# "dev": "nodemon src/server.js"
npm run dev
```

### Frontend Development

```bash
cd frontend

# Install dependencies
npm install

# Start dev server (hot reload)
npm run dev

# Access at: http://localhost:5173
```

### Environment Variables

**Backend (.env):**
```bash
DATABASE_URL=postgresql://bmi_user:password@localhost:5432/bmidb
PORT=3000
NODE_ENV=development
CORS_ORIGIN=http://localhost:5173
```

**Frontend:**
Frontend gets API URL from current browser location by default.
To override, modify `src/api.js`:
```javascript
const API_BASE_URL = process.env.VITE_API_URL || '/api';
```

---

## Code Standards

### JavaScript/React Style Guide

**General Principles:**
- Use ES6+ syntax (arrow functions, destructuring, template literals)
- Prefer `const` over `let`, avoid `var`
- Use async/await over promise chains
- Maximum function length: 50 lines
- Maximum file length: 300 lines

**Backend Code Style:**
```javascript
// ✅ Good - Async/await with error handling
async function getMeasurements(req, res) {
  try {
    const result = await pool.query('SELECT * FROM measurements ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (error) {
    console.error('Database error:', error);
    res.status(500).json({ error: 'Failed to fetch measurements' });
  }
}

// ❌ Bad - No error handling, unclear variable names
function getMeasurements(req, res) {
  pool.query('SELECT * FROM measurements ORDER BY created_at DESC', (e, r) => {
    res.json(r.rows);
  });
}
```

**Frontend Code Style:**
```javascript
// ✅ Good - Functional component with hooks
import { useState, useEffect } from 'react';

export function MeasurementList() {
  const [measurements, setMeasurements] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchMeasurements();
  }, []);

  const fetchMeasurements = async () => {
    try {
      const data = await api.getMeasurements();
      setMeasurements(data);
    } catch (error) {
      console.error('Failed to fetch:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div>Loading...</div>;
  return <div>{/* render measurements */}</div>;
}

// ❌ Bad - Class component, inline styles, no error handling
class MeasurementList extends React.Component {
  componentDidMount() {
    fetch('/api/measurements')
      .then(r => r.json())
      .then(d => this.setState({data: d}));
  }
  render() {
    return <div style={{color: 'red'}}>{/* ... */}</div>;
  }
}
```

### Terraform Style Guide

```hcl
# ✅ Good - Descriptive names, proper formatting
resource "aws_instance" "bmi_application_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}"
    }
  )
}

# ❌ Bad - Unclear names, inline values
resource "aws_instance" "ec2" {
  ami = "ami-019715e0d74f695be"
  instance_type = "t3.medium"
}
```

### SQL Style Guide

```sql
-- ✅ Good - Clear naming, constraints, indexes
CREATE TABLE measurements (
    id SERIAL PRIMARY KEY,
    weight DECIMAL(5,2) NOT NULL CHECK (weight > 0),
    height DECIMAL(5,2) NOT NULL CHECK (height > 0),
    bmi DECIMAL(4,2) NOT NULL,
    measurement_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_measurements_date ON measurements(measurement_date DESC);
CREATE INDEX idx_measurements_created ON measurements(created_at DESC);

-- ❌ Bad - No constraints, unclear names
CREATE TABLE m (
    id SERIAL,
    w DECIMAL,
    h DECIMAL,
    b DECIMAL
);
```

---

## Testing Requirements

### Before Submitting PR

**All PRs must pass:**

1. **Linting:**
   ```bash
   # Backend (if configured)
   cd backend && npm run lint
   
   # Frontend (if configured)
   cd frontend && npm run lint
   ```

2. **Unit Tests:**
   ```bash
   cd backend && npm test
   cd frontend && npm test
   ```

3. **Build Test:**
   ```bash
   cd frontend && npm run build
   # Must complete without errors
   ```

4. **Manual Testing:**
   - Test affected features in browser
   - Verify API endpoints with curl/Postman
   - Check database changes

### Writing Tests

**Backend API Test Example:**
```javascript
// backend/tests/api.test.js
const request = require('supertest');
const app = require('../src/server');

describe('GET /api/measurements', () => {
  it('should return array of measurements', async () => {
    const response = await request(app).get('/api/measurements');
    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
  });
});
```

**Frontend Component Test Example:**
```javascript
// frontend/src/components/__tests__/MeasurementForm.test.jsx
import { render, screen, fireEvent } from '@testing-library/react';
import { MeasurementForm } from '../MeasurementForm';

test('submits form with valid data', async () => {
  render(<MeasurementForm />);
  
  fireEvent.change(screen.getByLabelText('Weight'), { target: { value: '70' } });
  fireEvent.change(screen.getByLabelText('Height'), { target: { value: '175' } });
  fireEvent.click(screen.getByText('Submit'));
  
  // Assert submission
});
```

---

## Pull Request Process

### 1. Pre-PR Checklist

- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] All tests pass
- [ ] Documentation updated
- [ ] Commit messages follow convention
- [ ] Branch is up to date with main
- [ ] No merge conflicts

### 2. Commit Message Convention

**Format:** `<type>(<scope>): <subject>`

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Build process, dependencies
- `perf`: Performance improvements
- `ci`: CI/CD changes

**Examples:**
```bash
git commit -m "feat(backend): Add weight goal tracking endpoint"
git commit -m "fix(frontend): Correct BMI calculation for metric units"
git commit -m "docs(readme): Add troubleshooting section"
git commit -m "refactor(calculations): Extract BMI logic to helper function"
git commit -m "chore(deps): Update express to v4.19.0"
```

### 3. Submit Pull Request

**Title:** Should match commit message format

**Description Template:**
```markdown
## Description
Brief description of what this PR does

## Changes
- Added feature X
- Fixed bug Y
- Updated documentation Z

## Testing
- [ ] Tested locally
- [ ] All tests pass
- [ ] Manual testing completed

## Screenshots (if UI changes)
[Attach screenshots]

## Deployment Notes
Any special considerations for deployment

## Rollback Plan
How to revert if issues occur
```

### 4. Code Review

**Reviewers will check:**
- Code quality and style compliance
- Test coverage
- Security implications
- Performance impact
- Documentation completeness

**Address feedback:**
```bash
# Make requested changes
git add .
git commit -m "refactor: Address review feedback"
git push origin feature/your-feature
```

### 5. Merge Process

**After approval:**
1. Squash commits if multiple small commits
2. Merge to main via GitHub UI
3. Delete feature branch
4. Deploy to production (if needed)

```bash
# After merge, update local main
git checkout main
git pull upstream main

# Clean up feature branch
git branch -d feature/your-feature
git push origin --delete feature/your-feature
```

---

## Infrastructure Changes

### Terraform Change Workflow

**1. Plan Infrastructure Changes:**
```bash
cd terraform

# Make changes to .tf files
nano main.tf

# Validate syntax
terraform validate

# Format code
terraform fmt -recursive

# Preview changes
terraform plan -out=plan.tfplan
```

**2. Review Impact:**
```bash
# Review plan output carefully:
# - Resources to add (green +)
# - Resources to change (yellow ~)
# - Resources to destroy (red -)

# Check for:
# - Unintended deletions
# - Instance replacements (causes downtime)
# - Security group changes
```

**3. Test in Dev Environment:**
```bash
# Use separate workspace or tfvars
terraform workspace new dev
terraform apply -var-file=dev.tfvars

# Or use separate directory
cp -r terraform terraform-dev
cd terraform-dev
# Edit backend.tf to use different state key
terraform init
terraform apply
```

**4. Apply to Production:**
```bash
# Backup current state
terraform state pull > backup-state-$(date +%Y%m%d-%H%M%S).json

# Apply changes
terraform apply

# Monitor deployment
# Watch cloud-init logs if userdata changed
```

**5. Rollback if Needed:**
```bash
# Revert code changes
git revert <commit-hash>
terraform apply

# Or restore previous state
terraform state push backup-state-20260224-103000.json
```

### Breaking Changes

**If change causes instance replacement:**
1. Notify team (downtime expected)
2. Backup database before apply
3. Consider in-place updates instead:
   ```bash
   # SSH and update manually instead of destroy/create
   ssh ubuntu@<IP>
   cd /home/ubuntu/bmi-health-tracker
   git pull
   ./IMPLEMENTATION_AUTO.sh
   ```

---

## Database Migrations

### Creating New Migration

```bash
# Create migration file
cd backend/migrations
nano 003_add_user_notes.sql
```

**Migration template:**
```sql
-- Migration: 003_add_user_notes.sql
-- Description: Add notes field to measurements table
-- Author: Your Name
-- Date: 2026-02-24

BEGIN;

-- Add column
ALTER TABLE measurements 
ADD COLUMN notes TEXT;

-- Create index if needed
CREATE INDEX idx_measurements_notes ON measurements USING gin(to_tsvector('english', notes));

COMMIT;

-- Rollback script (keep in comments)
-- ALTER TABLE measurements DROP COLUMN notes;
-- DROP INDEX IF EXISTS idx_measurements_notes;
```

### Applying Migrations

**Automated:** IMPLEMENTATION_AUTO.sh applies all migrations in order

**Manual:**
```bash
PGPASSWORD=<pass> psql -U bmi_user -d bmidb -h localhost -f migrations/003_add_user_notes.sql
```

### Migration Best Practices

- ✅ Use transactions (BEGIN/COMMIT)
- ✅ Include rollback script in comments
- ✅ Test on dev database first
- ✅ Make changes backward compatible when possible
- ✅ Use `IF NOT EXISTS` for idempotency
- ❌ Never modify existing migration files
- ❌ Avoid data-destructive operations without backup

---

## Security Guidelines

### Secrets Management

**Never commit:**
- `.env` files
- `terraform.tfvars`
- Private keys
- API tokens
- Database passwords

**Git-ignored files (already configured):**
```gitignore
*.tfvars
!*.tfvars.example
.env
.env.local
*.pem
*.key
```

### Code Security Checklist

- [ ] No hardcoded credentials
- [ ] SQL injection prevention (parameterized queries)
- [ ] Input validation on all API endpoints
- [ ] XSS prevention (React escapes by default)
- [ ] CORS configured appropriately
- [ ] Rate limiting on API (future)
- [ ] Authentication/authorization (future)

### SQL Injection Prevention

```javascript
// ✅ Good - Parameterized query
const result = await pool.query(
  'SELECT * FROM measurements WHERE id = $1',
  [userId]
);

// ❌ Bad - SQL injection vulnerable
const result = await pool.query(
  `SELECT * FROM measurements WHERE id = ${userId}`
);
```

### Dependency Security

```bash
# Check for vulnerabilities
npm audit

# Update vulnerable packages
npm audit fix

# Review high-severity issues
npm audit --audit-level=high
```

---

## Review Checklist for Reviewers

### Code Review

- [ ] Follows project code style
- [ ] No security vulnerabilities
- [ ] Proper error handling
- [ ] Tests included and passing
- [ ] Documentation updated
- [ ] No hardcoded secrets
- [ ] Performance considerations addressed

### Infrastructure Review

- [ ] Terraform plan reviewed
- [ ] No unintended resource deletions
- [ ] State backup created
- [ ] Changes tested in dev environment
- [ ] Downtime communicated if applicable
- [ ] Rollback plan documented

### Approval Process

**Required approvals:**
- 1 approval for code changes
- 2 approvals for infrastructure changes
- Security team approval for security-related changes

---

## 🧑‍💻 Author

*Md. Sarowar Alam*  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---
