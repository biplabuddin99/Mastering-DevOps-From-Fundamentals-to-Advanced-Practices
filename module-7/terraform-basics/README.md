# Terraform Basics - AWS Infrastructure Projects

A collection of progressive Terraform projects demonstrating AWS infrastructure management from beginner to production-ready implementations.

## 📚 Projects Overview

This repository contains six Terraform projects, each building upon the previous one in complexity and best practices:

| Project | Level | State Management | Infrastructure | Use Case |
|---------|-------|------------------|----------------|----------|
| [first-ec2-example](#1-first-ec2-example) | Beginner | Local | Default VPC | Learning basics |
| [ec2-project](#2-ec2-project) | Intermediate | Local | User-provided | Modular approach |
| [ec2-project-with-userdata](#3-ec2-project-with-userdata) | Intermediate | Local | User-provided | EC2 with user data |
| [ec2-project-s3-backend](#4-ec2-project-s3-backend) | Advanced | S3 | User-provided | Team collaboration |
| [multi-instance-modules](#5-multi-instance-modules) | Advanced | Local | User-provided | Module reusability |
| [complete-infrastructure](#6-complete-infrastructure) | Production | S3 | Creates all | Full automation |

---

## 1. first-ec2-example

**🎯 Purpose:** Learn Terraform basics with a simple EC2 instance

### What You'll Learn
- Installing Terraform (Windows/Linux/macOS)
- Basic Terraform workflow (init, plan, apply, destroy)
- AWS provider configuration
- Creating your first EC2 instance

### Features
- ✅ Minimal configuration (single `.tf` file)
- ✅ Hardcoded credentials (learning only)
- ✅ Uses default VPC
- ✅ Local state management
- ⚠️ Not production-ready

### Quick Start
```bash
cd first-ec2-example
# Edit first_ec2.tf with your AWS credentials
terraform init
terraform apply
```

### Best For
- First-time Terraform users
- Understanding basic concepts
- Quick testing and experimentation

---

## 2. ec2-project

**🎯 Purpose:** Production-ready EC2 deployment with existing AWS infrastructure

### What You'll Learn
- Terraform modules
- AWS named profiles (secure authentication)
- Variable management
- Separation of concerns
- Using existing VPC/Subnet/Security Groups

### Features
- ✅ Modular architecture
- ✅ AWS named profiles (no hardcoded credentials)
- ✅ Requires existing VPC, Subnet, Security Group
- ✅ Variable-driven configuration
- ✅ Local state file
- ✅ Production-grade structure

### Quick Start
```bash
cd ec2-project
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS resources
terraform init
terraform apply
```

### Best For
- Organizations with existing AWS infrastructure
- Projects requiring security and modularity
- Single developer or small teams

---

## 3. ec2-project-with-userdata

**🎯 Purpose:** Production-ready EC2 deployment with user data script for automated instance configuration

### What You'll Learn
- User data scripts for instance initialization
- Automated software installation on boot
- Web server configuration
- All benefits from ec2-project

### Features
- ✅ All features from ec2-project
- ✅ User data script support
- ✅ Automated Apache installation and configuration
- ✅ Custom startup scripts
- ✅ Instance bootstrap automation

### Quick Start
```bash
cd ec2-project-with-userdata
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and user-data.sh as needed
terraform init
terraform apply
```

### Best For
- Instances requiring automated configuration
- Web servers needing automatic setup
- Standardized instance deployment
- DevOps automation workflows

---

## 4. ec2-project-s3-backend

**🎯 Purpose:** Team collaboration with remote state management

### What You'll Learn
- S3 backend configuration
- Remote state management
- State versioning and encryption
- Team collaboration workflows
- Optional DynamoDB state locking

### Features
- ✅ Same EC2 module as ec2-project
- ✅ S3 backend for state storage
- ✅ State encryption and versioning
- ✅ Requires existing VPC, Subnet, Security Group
- ✅ AWS named profiles
- ✅ Team-ready infrastructure
- ⚠️ State locking optional (requires DynamoDB)

### Quick Start
```bash
# Create S3 bucket first
aws s3 mb s3://your-state-bucket --region us-west-2

cd ec2-project-s3-backend
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and main.tf backend config
terraform init
terraform apply
```

### Best For
- Team environments
- Multiple developers collaborating
- Production deployments
- Organizations requiring state audit trails

---

## 4. ec2-project-s3-backend

**🎯 Purpose:** Team collaboration with remote state management

### What You'll Learn
- S3 backend configuration
- Remote state management
- State versioning and encryption
- Team collaboration workflows
- Optional DynamoDB state locking

### Features
- ✅ Same EC2 module as ec2-project
- ✅ S3 backend for state storage
- ✅ State encryption and versioning
- ✅ Requires existing VPC, Subnet, Security Group
- ✅ AWS named profiles
- ✅ Team-ready infrastructure
- ⚠️ State locking optional (requires DynamoDB)

### Quick Start
```bash
# Create S3 bucket first
aws s3 mb s3://your-state-bucket --region us-west-2

cd ec2-project-s3-backend
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and main.tf backend config
terraform init
terraform apply
```

### Best For
- Team environments
- Multiple developers collaborating
- Production deployments
- Organizations requiring state audit trails

---

## 5. multi-instance-modules

**🎯 Purpose:** Demonstrate module reusability by deploying multiple instances

### What You'll Learn
- Module reusability (DRY principle)
- Deploying multiple infrastructure components with one module
- Multi-tier architecture (Web, App, DB, Bastion)
- Different configurations for same module
- Network segmentation (public/private subnets)
- Bastion host pattern for secure SSH access

### Features
- ✅ **One module, four instances** (Web, App, DB, Bastion)
- ✅ 3-tier architecture deployment
- ✅ Different instance types per tier
- ✅ Public and private subnet separation
- ✅ Unique user data scripts per instance
- ✅ Different security groups per tier
- ✅ Role-based tagging
- ✅ SSH via bastion host
- ✅ Local state management

### Quick Start
```bash
cd multi-instance-modules
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS resources
terraform init
terraform apply
```

### What Gets Deployed

```
Web Server (t2.micro)    → Public Subnet  → Apache HTTP
App Server (t2.small)    → Private Subnet → Java Runtime
DB Server (t2.medium)    → Private Subnet → Database
Bastion Host (t2.micro)  → Public Subnet  → SSH Gateway
```

### Best For
- Understanding module reusability
- Learning multi-tier architectures
- Real-world application patterns
- Scaling infrastructure with modules
- Network security best practices

---

## 6. complete-infrastructure

**🎯 Purpose:** Full AWS infrastructure automation from scratch

### What You'll Learn
- Creating VPC and networking from scratch
- Multi-module architecture
- Security group management
- Complete infrastructure as code
- S3 backend for team collaboration
- User data for instance initialization

### Features
- ✅ Creates complete infrastructure:
  - VPC with custom CIDR
  - Public subnet with Internet Gateway
  - Route tables
  - Security Group (SSH, HTTP, HTTPS)
  - EC2 instance with Apache
- ✅ S3 backend for state
- ✅ AWS named profiles
- ✅ User-defined key pair
- ✅ Modular design (VPC, Security Group, EC2)
- ✅ Apache web server auto-installed
- ✅ Production-ready architecture

### Quick Start
```bash
# Create S3 bucket and key pair first
aws s3 mb s3://your-state-bucket --region us-west-2
aws ec2 create-key-pair --key-name your-key --query 'KeyMaterial' --output text > your-key.pem

cd complete-infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and main.tf backend config
terraform init
terraform apply
```

### Best For
- Greenfield projects
- Complete infrastructure automation
- Organizations wanting full IaC control
- Multi-environment deployments
- Learning complete AWS networking

---

## 🚀 Learning Path

**Recommended progression:**

1. **Start with `first-ec2-example`**
   - Learn Terraform basics
   - Understand the workflow
   - Get comfortable with commands

2. **Move to `ec2-project`**
   - Learn modular architecture
   - Use secure authentication (named profiles)
   - Work with existing infrastructure

3. **Practice with `ec2-project-with-userdata`**
   - Add instance automation
   - Learn user data scripts
   - Automate instance configuration

4. **Advance to `ec2-project-s3-backend`**
   - Implement remote state
   - Understand team collaboration
   - Learn state management best practices

5. **Practice with `multi-instance-modules`**
   - Master module reusability
   - Deploy multi-tier architecture
   - Understand real-world patterns
   - Learn network segmentation

6. **Master `complete-infrastructure`**
   - Create full infrastructure from scratch
   - Combine all concepts
   - Build production-ready systems

---

## 📋 Prerequisites

### For All Projects
- Terraform >= 1.0
- AWS Account
- Basic command line knowledge

### Project-Specific

| Project | Additional Requirements |
|---------|------------------------|
| first-ec2-example | AWS Access/Secret Keys |
| ec2-project | AWS CLI, Named Profile, Existing VPC/Subnet/SG |
| ec2-project-with-userdata | Same as ec2-project |
| ec2-project-s3-backend | S3 Bucket, Same as ec2-project |
| multi-instance-modules | Same as ec2-project, Public+Private Subnets, 4 SGs |
| complete-infrastructure | S3 Bucket, Existing Key Pair |

---

## 🔐 Security Comparison

| Project | Authentication | State Storage | Security Level |
|---------|---------------|---------------|----------------|
| first-ec2-example | Hardcoded | Local | ❌ Learning only |
| ec2-project | Named Profile | Local | ✅ Good |
| ec2-project-with-userdata | Named Profile | Local | ✅ Good |
| ec2-project-s3-backend | Named Profile | S3 | ✅✅ Better |
| multi-instance-modules | Named Profile | Local | ✅ Good |
| complete-infrastructure | Named Profile | S3 | ✅✅✅ Best |

---

## 🏗️ Infrastructure Comparison

| Component | first-ec2 | ec2-project | ec2-userdata | ec2-s3-backend | multi-instance | complete-infra |
|-----------|-----------|-------------|--------------|----------------|----------------|----------------|
| VPC | Default | User-provided | User-provided | User-provided | User-provided | ✅ Created |
| Subnet | Default | User-provided | User-provided | User-provided | Public+Private | ✅ Created |
| Internet Gateway | Default | Existing | Existing | Existing | Existing | ✅ Created |
| Route Table | Default | Existing | Existing | Existing | Existing | ✅ Created |
| Security Group | Default | User-provided | User-provided | User-provided | 4 Different SGs | ✅ Created |
| EC2 Instances | 1 | 1 | 1 | 1 | **4 (Multi-tier)** | 1 |
| Web Server | ❌ | ❌ | ✅ Apache | ❌ | ✅ Apache | ✅ Apache |
| App Server | ❌ | ❌ | ❌ | ❌ | ✅ Java | ❌ |
| DB Server | ❌ | ❌ | ❌ | ❌ | ✅ Database | ❌ |
| Bastion Host | ❌ | ❌ | ❌ | ❌ | ✅ SSH Gateway | ❌ |
| Module Reuse | ❌ | ✅ Single | ✅ Single | ✅ Single | **✅ Multiple** | ✅ Multiple |

---

## 📦 Project Structure

```
terraform-basics/
├── README.md                        # This file
├── first-ec2-example/
│   ├── README.md                    # Installation & basics
│   ├── first_ec2.tf
│   └── .gitignore
├── ec2-project/
│   ├── README.md                    # Modules & local state
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── .gitignore
│   └── modules/
│       └── ec2/
├── ec2-project-with-userdata/
│   ├── README.md                    # User data & automation
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── user-data.sh                 # Bootstrap script
│   ├── terraform.tfvars.example
│   ├── .gitignore
│   └── modules/
│       └── ec2/
├── ec2-project-s3-backend/
│   ├── README.md                    # S3 backend & collaboration
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── .gitignore
│   └── modules/
│       └── ec2/
├── multi-instance-modules/
│   ├── README.md                    # Module reusability demo
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── .gitignore
│   └── modules/
│       └── ec2/
└── complete-infrastructure/
    ├── README.md                    # Complete infrastructure
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars.example
    ├── .gitignore
    └── modules/
        ├── vpc/
        ├── security-group/
        └── ec2/
```

---

## 🛠️ Common Commands

### Initialize Project
```bash
terraform init
```

### Validate Configuration
```bash
terraform validate
```

### Format Code
```bash
terraform fmt
```

### Plan Changes
```bash
terraform plan
```

### Apply Changes
```bash
terraform apply
```

### Show Current State
```bash
terraform show
```

### View Outputs
```bash
terraform output
```

### Destroy Resources
```bash
terraform destroy
```

---

## 💡 Tips & Best Practices

### General
- Always run `terraform plan` before `terraform apply`
- Use version control (git) for your Terraform code
- Never commit `.tfvars` files or state files to git
- Use meaningful resource names
- Add tags to all resources for better organization

### State Management
- Use S3 backend for production (ec2-project-s3-backend, complete-infrastructure)
- Enable S3 versioning for state file history
- Enable encryption for sensitive data
- Consider DynamoDB for state locking in team environments

### Security
- Never hardcode credentials (except first-ec2-example for learning)
- Use AWS named profiles or IAM roles
- Restrict Security Group rules to minimum required
- Use specific CIDR blocks instead of 0.0.0.0/0 when possible
- Rotate access keys regularly

### Modules
- Keep modules focused and reusable
- Document module inputs and outputs
- Version your modules
- Test modules independently

---

## 🔍 Troubleshooting

### Common Issues

**Terraform not found**
```bash
# Check installation
terraform --version

# If not found, see first-ec2-example/README.md for installation
```

**AWS credentials error**
```bash
# Configure AWS CLI
aws configure --profile your-profile-name

# Verify
aws sts get-caller-identity --profile your-profile-name
```

**State lock error**
```bash
# Force unlock (use carefully!)
terraform force-unlock <LOCK_ID>
```

**Resource already exists**
```bash
# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0
```

---

## 📚 Additional Resources

### Official Documentation
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Registry](https://registry.terraform.io/)

### Learning Resources
- [HashiCorp Learn](https://learn.hashicorp.com/terraform)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

### Tools
- [Terraform Cloud](https://cloud.hashicorp.com/products/terraform)
- [tflint](https://github.com/terraform-linters/tflint) - Terraform linter
- [terraform-docs](https://terraform-docs.io/) - Documentation generator

---

## 🤝 Contributing

Each project is self-contained and documented. To modify or extend:

1. Choose the appropriate project based on your needs
2. Follow the project's README for setup
3. Test changes with `terraform plan`
4. Document any modifications

---

## 📝 License

These projects are for educational purposes. Use at your own risk and always follow your organization's security policies.

---

## ⚠️ Cost Warning

**All projects create AWS resources that may incur costs!**

- **Free Tier Eligible:** t2.micro/t3.micro instances (750 hours/month)
- **Always destroy resources when done:** `terraform destroy`
- **Monitor AWS billing dashboard regularly**

---

## 🎓 Course Information

**Course:** Ostad Batch-08, Module-06  
**Topic:** Terraform Basics  
**Projects:** Progressive learning from basics to production-ready infrastructure

---

## 🧑‍💻 Author

**Md. Sarowar Alam**  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: [linkedin.com/in/sarowar](https://www.linkedin.com/in/sarowar/)  
🐙 GitHub: [@md-sarowar-alam](https://github.com/md-sarowar-alam)

---

### License

This guide is provided as educational material for DevOps engineers.

---

**© 2026 Md. Sarowar Alam. All rights reserved.**

---

**Happy Terraforming! 🚀**
