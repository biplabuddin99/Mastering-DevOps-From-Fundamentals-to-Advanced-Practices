# Changelog

All notable changes to BMI Health Tracker will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-02-24

### Added
- ✨ Initial production release
- ✨ Terraform modular infrastructure architecture
- ✨ Automated deployment via IMPLEMENTATION_AUTO.sh (946 lines)
- ✨ Non-interactive deployment mode with environment variables
- ✨ Cloud-init zero-touch provisioning
- ✨ Systemd service management for backend
- ✨ Nginx reverse proxy with caching and compression
- ✨ PostgreSQL database with migrations
- ✨ React + Vite frontend with hot reload
- ✨ S3 backend for Terraform state (encrypted)
- ✨ BMI calculation and tracking functionality
- ✨ Trend visualization with Chart.js
- ✨ Responsive UI design
- ✨ RESTful API with Express.js
- ✨ Database connection pooling
- ✨ Comprehensive logging infrastructure
- ✨ Production-ready README and operations guides

### Infrastructure
- 🏗️ AWS EC2 t3.medium instance deployment
- 🏗️ Ubuntu 22.04 LTS base image
- 🏗️ 20GB encrypted EBS root volume
- 🏗️ IMDSv2 enforcement
- 🏗️ Public IP with existing VPC/subnet/security group
- 🏗️ Reusable EC2 Terraform module

### Configuration
- ⚙️ AWS named profile support
- ⚙️ Parameterized database credentials via templatefile
- ⚙️ Environment-based configuration (.env files)
- ⚙️ CORS configuration for API access
- ⚙️ Nginx gzip compression
- ⚙️ Static asset caching

### Documentation
- 📚 Complete README with onboarding guide
- 📚 CONTRIBUTING.md for development workflow
- 📚 OPERATIONS.md for day-to-day procedures
- 📚 SECURITY.md for security policies
- 📚 CHANGELOG.md for version tracking
- 📚 Terraform configuration examples
- 📚 Backend .env.example template

### Fixed
- 🐛 Cloud-init deadlock (removed self-referential wait)
- 🐛 Truncated echo statement in user-data.sh (syntax error)
- 🐛 NVM installation permission denied (added sudo -H flag)
- 🐛 Environment variable overwriting in IMPLEMENTATION_AUTO.sh (conditional assignment)
- 🐛 Interactive password prompts in automated deployment

### Security
- 🔒 S3 state encryption enabled
- 🔒 EBS volume encryption at rest
- 🔒 IMDSv2 required (prevents SSRF)
- 🔒 PostgreSQL password authentication (md5)
- 🔒 Nginx security headers configured
- 🔒 Sensitive variables marked in Terraform

### Performance
- ⚡ Vite for fast frontend builds (~30s)
- ⚡ Production build optimization
- ⚡ Static asset caching (1 year)
- ⚡ Gzip compression for HTTP responses
- ⚡ Database indexes on common queries

### Operations
- 🔧 Automated health checks in deployment script
- 🔧 Service auto-restart on failure (systemd)
- 🔧 Structured logging to dedicated files
- 🔧 Backup directory creation and rotation
- 🔧 PostgreSQL connection testing

---

## [Unreleased]

### Planned Features
- User authentication and authorization
- Multi-user support with accounts
- Goal setting and tracking
- Email notifications for milestones
- Mobile-responsive improvements
- Dark mode theme
- Export data to CSV/PDF
- Historical data comparison
- BMI category recommendations

### Planned Infrastructure
- RDS PostgreSQL migration
- Multi-AZ deployment
- Application Load Balancer
- Auto Scaling Group
- CloudFront CDN for frontend
- Route 53 DNS management
- AWS Secrets Manager integration
- CloudWatch alerts and dashboards
- Automated backup to S3 with lifecycle
- Blue-green deployment support

### Planned Security
- SSL/TLS certificate automation
- JWT authentication
- API rate limiting
- WAF integration
- Security group tightening
- Secrets rotation automation
- Vulnerability scanning in CI/CD
- Security audit logging

---

## Version History

### Versioning Strategy

**MAJOR.MINOR.PATCH**

- **MAJOR:** Breaking API changes, major architecture changes
- **MINOR:** New features, backward-compatible enhancements
- **PATCH:** Bug fixes, security patches, minor updates

### Breaking Changes

None yet (v1.0.0 is first release)

---

## Migration Guides

When breaking changes are introduced, migration guides will be provided here.

---

## 🧑‍💻 Author

*Md. Sarowar Alam*  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---

**Note:** This project follows [Semantic Versioning](https://semver.org/) and maintains this changelog according to [Keep a Changelog](https://keepachangelog.com/) format.
