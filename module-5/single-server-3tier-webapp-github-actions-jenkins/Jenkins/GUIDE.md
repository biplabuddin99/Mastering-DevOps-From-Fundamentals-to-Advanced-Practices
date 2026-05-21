# Jenkins Integration - Complete Navigation Guide

This document provides a structured path through all Jenkins documentation, organized by the three main objectives.

---

## 📖 Documentation Structure

### 1️⃣ **AWS Server Creation & Jenkins Server Setup**
**Goal**: Set up a Jenkins server on AWS EC2 Ubuntu 24.04 from scratch

📄 **Guide**: [CreateJenkinsServer.md](./CreateJenkinsServer.md)

**What's Covered**:
- ✅ Create AWS EC2 instance with proper configuration
- ✅ Configure security groups (ports 8080, 22, 80, 443)
- ✅ Connect to EC2 via SSH
- ✅ Install Jenkins on Ubuntu 24.04
- ✅ Access Jenkins web GUI
- ✅ Complete initial setup wizard
- ✅ Install essential plugins (Git, SSH, NodeJS, etc.)
- ✅ **How to add Git to Jenkins** (Plugin installation and configuration)
- ✅ Configure global settings (NodeJS, Git, SSH)
- ✅ Create admin users
- ✅ Security best practices
- ✅ Troubleshooting common issues

**Start here if**: You don't have a Jenkins server yet, or want to create a new one

---

### 2️⃣ **Jenkins Pipeline Examples & Basics**
**Goal**: Learn how to create and execute Jenkins pipelines

📄 **Guide**: [StartJenkins.md](./StartJenkins.md)

📁 **Examples**: [examples/](./examples/) - Standalone Groovy files

**What's Covered**:
- ✅ Jenkins pipeline concepts (stages, steps, agents)
- ✅ **How to create pipeline jobs in Jenkins UI**
- ✅ **How to execute pipelines**
- ✅ Declarative vs Scripted pipelines
- ✅ 7 progressive examples with complete code:
  1. **Hello World** - Basic pipeline verification ([examples/01-hello-world.groovy](./examples/01-hello-world.groovy))
  2. **Parameterized Build** - User inputs ([examples/02-parameterized-build.groovy](./examples/02-parameterized-build.groovy))
  3. **Multi-Stage Pipeline** - Build/Test/Deploy workflow ([examples/03-multi-stage-pipeline.groovy](./examples/03-multi-stage-pipeline.groovy))
  4. **Git Integration** - Clone repositories with credentials ([examples/04-git-integration.groovy](./examples/04-git-integration.groovy))
  5. **Environment Variables** - Variable management ([examples/05-environment-variables.groovy](./examples/05-environment-variables.groovy))
  6. **Conditional Execution** - When directives, approvals ([examples/06-conditional-execution.groovy](./examples/06-conditional-execution.groovy))
  7. **Advanced Patterns** - Parallel execution, error handling ([examples/07-advanced-patterns.groovy](./examples/07-advanced-patterns.groovy))
- ✅ Common pipeline patterns
- ✅ Troubleshooting tips

**Start here if**: You have Jenkins running and want to learn pipeline basics

---

### 3️⃣ **Three-Tier Application Deployment**
**Goal**: Deploy the BMI Health Tracker application to AWS EC2 with Jenkins

📁 **Folder**: [3-Tier/](./3-Tier/)

📄 **Main Guide**: [3-Tier/ThreeTierWithJenkins.md](./3-Tier/ThreeTierWithJenkins.md)

📄 **Quick Reference**: [3-Tier/README.md](./3-Tier/README.md)

🔐 **Security Guide**: [CREDENTIALS_GUIDE.md](./CREDENTIALS_GUIDE.md)

**What's Covered**:
- ✅ **All secrets stored in Jenkins Credentials Manager** (no hardcoded passwords)
- ✅ **How to add Git credentials to Jenkins**
- ✅ **How to add SSH keys for EC2 access**
- ✅ **How to add database passwords securely**
- ✅ Architecture overview (Frontend/Backend/Database)
- ✅ Prerequisites and requirements
- ✅ Step-by-step deployment process
- ✅ Two production-ready pipelines:
  - **Jenkinsfile** - Single environment deployment ([3-Tier/Jenkinsfile](./3-Tier/Jenkinsfile))
  - **Jenkinsfile.multibranch** - Multi-environment (dev/staging/prod) ([3-Tier/Jenkinsfile.multibranch](./3-Tier/Jenkinsfile.multibranch))
- ✅ Support scripts:
  - **check-prerequisites.sh** - Verify EC2 setup ([3-Tier/scripts/check-prerequisites.sh](./3-Tier/scripts/check-prerequisites.sh))
  - **health-check.sh** - Application health monitoring ([3-Tier/scripts/health-check.sh](./3-Tier/scripts/health-check.sh))
  - **rollback-jenkins.sh** - Automatic rollback on failure ([3-Tier/scripts/rollback-jenkins.sh](./3-Tier/scripts/rollback-jenkins.sh))
- ✅ Fresh deployment vs update deployment
- ✅ Webhook configuration (auto-deploy on Git push)
- ✅ Comparison: GitHub Actions vs Jenkins
- ✅ Troubleshooting and debugging

**Start here if**: You want to deploy the three-tier application with Jenkins

---

## 🎯 Quick Start Paths

### Path A: Complete Beginner (No Jenkins Server)
```
1. CreateJenkinsServer.md    → Set up Jenkins on AWS EC2
2. StartJenkins.md            → Learn pipeline basics
3. 3-Tier/                    → Deploy the application
```

### Path B: Have Jenkins, New to Pipelines
```
1. StartJenkins.md            → Learn pipeline basics
2. 3-Tier/                    → Deploy the application
```

### Path C: Know Jenkins, Deploy Application
```
1. CREDENTIALS_GUIDE.md       → Set up credentials securely
2. 3-Tier/README.md           → Quick deployment overview
3. 3-Tier/ThreeTierWithJenkins.md → Full deployment guide
```

---

## 🔑 Key Topics: How to Add Git to Jenkins

### During Jenkins Setup
See [CreateJenkinsServer.md](./CreateJenkinsServer.md) → Section 8: Install Essential Plugins

**Steps**:
1. Install **Git Plugin** (usually pre-installed)
2. Install **GitHub Plugin** (for webhooks and integration)
3. Configure Git tool path (Manage Jenkins → Tools → Git installations)

### Adding Git Credentials
See [CREDENTIALS_GUIDE.md](./CREDENTIALS_GUIDE.md) → Section: GitHub Access Token

**Steps**:
1. Generate GitHub Personal Access Token
2. Jenkins → Manage Jenkins → Credentials → Add Credentials
3. Kind: Secret text
4. ID: `github-token`
5. Secret: [Your GitHub token]

### Using Git in Pipelines
See [examples/04-git-integration.groovy](./examples/04-git-integration.groovy)

**Example**:
```groovy
checkout([
    $class: 'GitSCM',
    branches: [[name: '*/main']],
    userRemoteConfigs: [[
        url: 'https://github.com/your-org/repo.git',
        credentialsId: 'github-token'  // References Jenkins credential
    ]]
])
```

---

## 🔐 Credentials Manager Topics

### Complete Security Guide
📄 [CREDENTIALS_GUIDE.md](./CREDENTIALS_GUIDE.md)

**What's Covered**:
- ✅ How Jenkins Credentials Manager works
- ✅ **How to add SSH keys** for EC2 access
- ✅ **How to add Git/GitHub credentials**
- ✅ **How to add database passwords**
- ✅ **How to use credentials in pipelines**
- ✅ Security best practices
- ✅ Credential rotation
- ✅ Troubleshooting credential issues

**All credentials types used**:
- `ec2-ssh-key` - SSH Username with private key (for AWS EC2)
- `db-password` - Secret text (for PostgreSQL)
- `github-token` - Secret text (for private Git repositories)
- `db-password-production/staging/dev` - Environment-specific secrets

---

## 📊 Documentation Map

```
Jenkins/
│
├── README.md                          ← You are here
├── GUIDE.md                           ← This navigation guide
│
├── 1️⃣ AWS & Jenkins Setup
│   └── CreateJenkinsServer.md         → Complete EC2 and Jenkins setup
│                                         Includes: How to add Git plugin
│
├── 2️⃣ Pipeline Examples
│   ├── StartJenkins.md                → Pipeline tutorials and concepts
│   └── examples/                      → 7 standalone Groovy examples
│       ├── 01-hello-world.groovy
│       ├── 02-parameterized-build.groovy
│       ├── 03-multi-stage-pipeline.groovy
│       ├── 04-git-integration.groovy  → How to use Git in pipelines
│       ├── 05-environment-variables.groovy
│       ├── 06-conditional-execution.groovy
│       └── 07-advanced-patterns.groovy
│
├── 3️⃣ Application Deployment
│   └── 3-Tier/
│       ├── README.md                  → Quick reference
│       ├── ThreeTierWithJenkins.md    → Complete deployment guide
│       ├── Jenkinsfile                → Single-environment pipeline
│       ├── Jenkinsfile.multibranch    → Multi-environment pipeline
│       └── scripts/
│           ├── check-prerequisites.sh
│           ├── health-check.sh
│           └── rollback-jenkins.sh
│
└── 🔐 Security
    └── CREDENTIALS_GUIDE.md           → How to add all credentials
                                          Includes: Git, SSH, passwords
```

---

## 🔍 Find Specific Topics

### "How do I...?"

| Question | Document | Section |
|----------|----------|---------|
| **Create AWS EC2 for Jenkins?** | [CreateJenkinsServer.md](./CreateJenkinsServer.md) | Section 2 |
| **Install Jenkins on Ubuntu?** | [CreateJenkinsServer.md](./CreateJenkinsServer.md) | Section 5 |
| **Add Git plugin to Jenkins?** | [CreateJenkinsServer.md](./CreateJenkinsServer.md) | Section 8 |
| **Configure Git in Jenkins?** | [CreateJenkinsServer.md](./CreateJenkinsServer.md) | Section 9 (Step 2) |
| **Add GitHub credentials?** | [CREDENTIALS_GUIDE.md](./CREDENTIALS_GUIDE.md) | Section: GitHub Access Token |
| **Add SSH key for EC2?** | [CREDENTIALS_GUIDE.md](./CREDENTIALS_GUIDE.md) | Section: EC2 SSH Access |
| **Create a pipeline job?** | [StartJenkins.md](./StartJenkins.md) | Each example section |
| **Execute a pipeline?** | [StartJenkins.md](./StartJenkins.md) | Run the Pipeline steps |
| **Use Git in pipeline?** | [examples/04-git-integration.groovy](./examples/04-git-integration.groovy) | Full example |
| **Deploy three-tier app?** | [3-Tier/ThreeTierWithJenkins.md](./3-Tier/ThreeTierWithJenkins.md) | Full guide |
| **Use credentials securely?** | [CREDENTIALS_GUIDE.md](./CREDENTIALS_GUIDE.md) | How Credentials Are Used |
| **Troubleshoot deployment?** | [3-Tier/ThreeTierWithJenkins.md](./3-Tier/ThreeTierWithJenkins.md) | Section 10 |

---

## 📱 Quick Command Reference

### Access Jenkins
```bash
# After installation
http://<EC2_PUBLIC_IP>:8080
```

### Connect to Jenkins Server
```bash
ssh -i jenkins-server-key.pem ubuntu@<JENKINS_EC2_IP>
```

### Jenkins Service Commands
```bash
# Check status
sudo systemctl status jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# View logs
sudo journalctl -u jenkins -f
```

### Get Initial Admin Password
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## 🎓 Learning Path with Hands-On Practice

### Week 1: Jenkins Setup
1. Read [CreateJenkinsServer.md](./CreateJenkinsServer.md)
2. Create AWS EC2 instance
3. Install and configure Jenkins
4. Install all required plugins (Git, SSH, NodeJS)
5. Configure Git and create test credentials

### Week 2: Pipeline Basics
1. Read [StartJenkins.md](./StartJenkins.md)
2. Create and run each example pipeline:
   - Start with Hello World
   - Add parameters
   - Build multi-stage pipeline
   - Practice Git integration
   - Test conditional execution
3. Experiment with modifications

### Week 3: Application Deployment
1. Read [CREDENTIALS_GUIDE.md](./CREDENTIALS_GUIDE.md)
2. Set up all credentials (SSH, Git, Database)
3. Read [3-Tier/README.md](./3-Tier/README.md) for overview
4. Follow [3-Tier/ThreeTierWithJenkins.md](./3-Tier/ThreeTierWithJenkins.md)
5. Deploy application to test EC2
6. Configure webhooks for auto-deployment
7. Test rollback procedures

---

## 💡 Pro Tips

### For AWS Setup
- ✅ Use t3.medium or larger for Jenkins (needs 4GB+ RAM)
- ✅ Enable termination protection
- ✅ Use Elastic IP for consistent Jenkins URL
- ✅ Configure security groups properly (ports 8080, 22)

### For Pipeline Development
- ✅ Start with inline scripts, move to SCM later
- ✅ Use declarative syntax (easier than scripted)
- ✅ Always use Jenkins Credentials Manager
- ✅ Test pipelines incrementally (stage by stage)
- ✅ Use `echo` statements for debugging

### For Deployments
- ✅ Never hardcode credentials in pipelines
- ✅ Always create backups before updates
- ✅ Implement health checks after deployment
- ✅ Set up automatic rollback on failure
- ✅ Use webhooks for automated deployments

---

## 🆘 Troubleshooting

### "I can't access Jenkins at port 8080"
- Check AWS security group allows port 8080
- Verify Jenkins is running: `sudo systemctl status jenkins`
- Check firewall: `sudo ufw status`
- See [CreateJenkinsServer.md](./CreateJenkinsServer.md) Section 12

### "Pipeline can't connect to Git"
- Verify Git plugin installed
- Check Git credentials in Jenkins
- Test Git URL manually: `git ls-remote <URL>`
- See [CREDENTIALS_GUIDE.md](./CREDENTIALS_GUIDE.md)

### "SSH to EC2 fails in pipeline"
- Verify ec2-ssh-key credential exists
- Check SSH key format (PEM)
- Test SSH manually from Jenkins server
- See [CREDENTIALS_GUIDE.md](./CREDENTIALS_GUIDE.md) Section: EC2 SSH Access

### "Deployment health checks fail"
- Check backend logs: `pm2 logs`
- Verify services running: `pm2 status`, `sudo systemctl status nginx`
- See [3-Tier/ThreeTierWithJenkins.md](./3-Tier/ThreeTierWithJenkins.md) Troubleshooting

---

## 📞 Support Resources

### Official Documentation
- **Jenkins Documentation**: https://www.jenkins.io/doc/
- **Pipeline Syntax**: https://www.jenkins.io/doc/book/pipeline/syntax/
- **Pipeline Examples**: https://www.jenkins.io/doc/pipeline/examples/

### Plugin Documentation
- **Git Plugin**: https://plugins.jenkins.io/git/
- **SSH Agent**: https://plugins.jenkins.io/ssh-agent/
- **NodeJS Plugin**: https://plugins.jenkins.io/nodejs/
- **Credentials Plugin**: https://plugins.jenkins.io/credentials/

### AWS Documentation
- **EC2 User Guide**: https://docs.aws.amazon.com/ec2/
- **Security Groups**: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html

---

## ✅ Checklist: Full Setup

Use this checklist to track your progress:

### Phase 1: Jenkins Server Setup
- [ ] AWS EC2 instance created with Ubuntu 24.04
- [ ] Security groups configured (8080, 22, 80)
- [ ] SSH connection working
- [ ] Jenkins installed and running
- [ ] Initial admin password retrieved
- [ ] Setup wizard completed
- [ ] Git plugin installed and configured
- [ ] SSH Agent plugin installed
- [ ] NodeJS plugin installed
- [ ] Admin user created

### Phase 2: Learn Pipelines
- [ ] Hello World pipeline executed successfully
- [ ] Parameterized pipeline tested
- [ ] Multi-stage pipeline created
- [ ] Git integration pipeline tested
- [ ] Environment variables example run
- [ ] Conditional execution tested
- [ ] Advanced patterns explored

### Phase 3: Application Deployment
- [ ] Target EC2 instance ready
- [ ] SSH key added to Jenkins credentials (ec2-ssh-key)
- [ ] Database password added (db-password)
- [ ] GitHub token added (if private repo)
- [ ] Single-environment pipeline job created
- [ ] Test deployment successful
- [ ] Health checks passing
- [ ] Webhook configured (optional)
- [ ] Rollback tested

---

## 🎯 Next Steps

After completing this guide:

1. **Optimize Your Setup**
   - Configure Jenkins backup strategy
   - Set up SSL/HTTPS for Jenkins
   - Implement monitoring and logging

2. **Expand Your Knowledge**
   - Explore Blue Ocean UI
   - Learn Jenkins shared libraries
   - Set up multi-branch pipelines
   - Integrate with Slack/Discord notifications

3. **Production Hardening**
   - Implement role-based access control
   - Set up Jenkins behind reverse proxy
   - Configure automatic backups
   - Enable audit logging

---

**Document Version**: 1.0  
**Last Updated**: December 30, 2025  
**Purpose**: Navigation guide for Jenkins integration

---

**Ready to start?** Choose your path above and dive into the documentation! 🚀
