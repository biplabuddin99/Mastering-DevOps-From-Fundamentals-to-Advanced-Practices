# Multi-Instance Deployment Using Terraform Modules

This project demonstrates the **power of Terraform modules** by deploying multiple EC2 instances with different configurations using a **single reusable module**.

## 🎯 Purpose

Learn how to:
- **Reuse a single module** to create multiple infrastructure components
- Deploy a **multi-tier architecture** (Web, App, DB, Bastion)
- Pass **different configurations** to the same module
- Manage **multiple instances** efficiently
- Use modules for **DRY (Don't Repeat Yourself)** principles

## 🏗️ Architecture

This configuration deploys a **3-tier architecture** plus a bastion host:

```
┌─────────────────────────────────────────────────────┐
│                  VPC (10.0.0.0/16)                  │
│                                                     │
│  ┌────────────────────┐  ┌─────────────────────┐  │
│  │  Public Subnet     │  │  Private Subnet     │  │
│  │                    │  │                     │  │
│  │  ┌──────────────┐  │  │  ┌──────────────┐  │  │
│  │  │ Web Server   │  │  │  │ App Server   │  │  │
│  │  │ (t2.micro)   │  │  │  │ (t2.small)   │  │  │
│  │  │ Apache+HTTP  │  │  │  │ Java/Python  │  │  │
│  │  └──────────────┘  │  │  └──────────────┘  │  │
│  │                    │  │                     │  │
│  │  ┌──────────────┐  │  │  ┌──────────────┐  │  │
│  │  │ Bastion Host │  │  │  │ DB Server    │  │  │
│  │  │ (t2.micro)   │  │  │  │ (t2.medium)  │  │  │
│  │  │ SSH Gateway  │  │  │  │ Database     │  │  │
│  │  └──────────────┘  │  │  └──────────────┘  │  │
│  │                    │  │                     │  │
│  └────────────────────┘  └─────────────────────┘  │
│           │                        │               │
│           ▼                        ▼               │
│   Internet Gateway          NAT Gateway            │
└─────────────────────────────────────────────────────┘
                    │
                    ▼
                Internet
```

## 📦 What Gets Created

### 1. **Web Server** (Public Subnet)
- **Purpose:** Frontend web server
- **Instance Type:** t2.micro
- **Software:** Apache HTTP Server
- **Access:** Public IP, HTTP/HTTPS
- **Module Source:** `./modules/ec2`

### 2. **Application Server** (Private Subnet)
- **Purpose:** Business logic/API layer
- **Instance Type:** t2.small
- **Software:** Java 11
- **Access:** Only from Web Server
- **Module Source:** `./modules/ec2`

### 3. **Database Server** (Private Subnet)
- **Purpose:** Data persistence layer
- **Instance Type:** t2.medium
- **Software:** Database (placeholder)
- **Access:** Only from App Server
- **Module Source:** `./modules/ec2`

### 4. **Bastion Host** (Public Subnet)
- **Purpose:** SSH gateway to private instances
- **Instance Type:** t2.micro
- **Software:** Base OS
- **Access:** SSH from your IP only
- **Module Source:** `./modules/ec2`

## 🔑 Key Concept: Module Reusability

### Single Module, Multiple Uses

All four instances use the **same EC2 module** (`./modules/ec2`) but with different configurations:

```hcl
# Web Server
module "web_server" {
  source            = "./modules/ec2"
  instance_name     = "web-server-dev"
  instance_type     = "t2.micro"
  subnet_id         = var.public_subnet_id
  security_group_id = var.web_security_group_id
  user_data         = "# Web server setup script"
  tags              = { Role = "WebServer" }
}

# App Server (same module, different config)
module "app_server" {
  source            = "./modules/ec2"
  instance_name     = "app-server-dev"
  instance_type     = "t2.small"
  subnet_id         = var.private_subnet_id
  security_group_id = var.app_security_group_id
  user_data         = "# App server setup script"
  tags              = { Role = "AppServer" }
}
```

## 📋 Prerequisites

- Terraform >= 1.0
- AWS CLI configured with named profile
- Existing AWS infrastructure:
  - VPC with public and private subnets
  - 4 separate security groups (web, app, db, bastion)
  - Key pair for SSH access
  - NAT Gateway (optional, for private subnet internet access)

## 🚀 Setup Instructions

### Step 1: Configure Variables

```bash
cd multi-instance-modules
cp terraform.tfvars.example terraform.tfvars
```

### Step 2: Edit `terraform.tfvars`

```hcl
aws_profile = "your-profile"
aws_region  = "us-west-2"
environment = "dev"

vpc_id             = "vpc-xxxxx"
public_subnet_id   = "subnet-xxxxx"  # For web & bastion
private_subnet_id  = "subnet-xxxxx"  # For app & db

# Create separate security groups for each tier
web_security_group_id     = "sg-xxxxx"  # HTTP/HTTPS from internet
app_security_group_id     = "sg-xxxxx"  # Traffic from web tier
db_security_group_id      = "sg-xxxxx"  # Traffic from app tier
bastion_security_group_id = "sg-xxxxx"  # SSH from your IP

ami_id = "ami-00f46ccd1cbfb363e"
key_name = "your-key-pair"
```

### Step 3: Initialize and Deploy

```bash
terraform init
terraform plan
terraform apply
```

### Step 4: Access Your Infrastructure

After deployment, Terraform outputs:

```bash
# Web Server (direct access)
ssh -i your-key.pem ec2-user@<web-public-ip>

# Bastion Host
ssh -i your-key.pem ec2-user@<bastion-public-ip>

# App Server (via bastion)
ssh -i your-key.pem -J ec2-user@<bastion-public-ip> ec2-user@<app-private-ip>

# Test Web Server
curl http://<web-public-ip>
```

## 📊 Module Structure

### EC2 Module (`modules/ec2/`)

**Inputs:**
```hcl
- instance_name       # Name tag
- ami_id              # AMI ID
- instance_type       # Instance size
- subnet_id           # Where to deploy
- security_group_id   # Security rules
- key_name            # SSH key
- user_data           # Initialization script
- root_volume_size    # Disk size
- tags                # Additional tags
```

**Outputs:**
```hcl
- instance_id
- public_ip
- private_ip
- public_dns
- instance_state
- arn
- availability_zone
```

## 🎓 Learning Objectives

### 1. **Module Reusability**
Instead of writing EC2 configuration 4 times, we write it **once** and reuse it **4 times**.

### 2. **Configuration Flexibility**
Each instance gets different:
- Instance types (t2.micro, t2.small, t2.medium)
- Subnets (public vs private)
- Security groups (different access rules)
- User data scripts (different software)
- Tags (different roles)

### 3. **Multi-Tier Architecture**
Real-world application architecture with:
- Frontend (Web Server)
- Backend (App Server)
- Database (DB Server)
- Management (Bastion Host)

### 4. **DRY Principle**
**Don't Repeat Yourself** - write code once, use everywhere.

## 🔐 Security Best Practices

### Network Segmentation
- **Public Subnet:** Web Server, Bastion (internet-facing)
- **Private Subnet:** App Server, DB Server (isolated)

### Security Group Rules

**Web Server SG:**
```
Inbound:  HTTP (80) from 0.0.0.0/0
          HTTPS (443) from 0.0.0.0/0
          SSH (22) from Bastion SG
Outbound: All traffic
```

**App Server SG:**
```
Inbound:  App Port (8080) from Web SG
          SSH (22) from Bastion SG
Outbound: All traffic
```

**DB Server SG:**
```
Inbound:  DB Port (3306/5432) from App SG
          SSH (22) from Bastion SG
Outbound: All traffic
```

**Bastion SG:**
```
Inbound:  SSH (22) from YOUR-IP/32
Outbound: All traffic
```

## 📤 Outputs

After deployment, you'll see:

```hcl
infrastructure_summary = {
  environment = "dev"
  web_server = {
    id         = "i-xxxxx"
    public_ip  = "3.x.x.x"
    private_ip = "10.0.1.x"
    type       = "t2.micro"
  }
  app_server = {
    id         = "i-xxxxx"
    private_ip = "10.0.2.x"
    type       = "t2.small"
  }
  db_server = {
    id         = "i-xxxxx"
    private_ip = "10.0.2.x"
    type       = "t2.medium"
  }
  bastion_host = {
    id        = "i-xxxxx"
    public_ip = "3.x.x.x"
    type      = "t2.micro"
  }
}
```

## 💡 Module Benefits

### Without Modules (Repetitive):
```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = var.public_subnet_id
  # ... 20 more lines
}

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = "t2.small"
  subnet_id     = var.private_subnet_id
  # ... 20 more lines (REPEATED!)
}

# Repeat for db and bastion... 100+ lines total!
```

### With Modules (Clean):
```hcl
module "web_server" {
  source        = "./modules/ec2"
  instance_name = "web-server"
  instance_type = "t2.micro"
  # ... only unique values
}

module "app_server" {
  source        = "./modules/ec2"
  instance_name = "app-server"
  instance_type = "t2.small"
  # ... only unique values
}

# Just 40 lines total! Clean and maintainable!
```

## 🔄 Scaling to Multiple Environments

You can easily replicate this entire infrastructure for different environments:

```bash
# Development
terraform workspace new dev
terraform apply -var="environment=dev"

# Staging
terraform workspace new staging
terraform apply -var="environment=staging"

# Production
terraform workspace new prod
terraform apply -var="environment=prod"
```

## 🛠️ Customization Examples

### Add More Instances

```hcl
# Add a monitoring server
module "monitoring_server" {
  source            = "./modules/ec2"
  instance_name     = "monitoring-server-${var.environment}"
  instance_type     = "t2.small"
  subnet_id         = var.public_subnet_id
  security_group_id = var.monitoring_sg_id
  # ...
}
```

### Use for_each for Dynamic Scaling

```hcl
# Deploy multiple app servers
variable "app_server_count" {
  default = 3
}

module "app_servers" {
  for_each = toset(["1", "2", "3"])
  
  source            = "./modules/ec2"
  instance_name     = "app-server-${each.key}"
  instance_type     = "t2.small"
  subnet_id         = var.private_subnet_id
  security_group_id = var.app_security_group_id
  # ...
}
```

## 🧪 Testing

### Verify Instances
```bash
terraform output infrastructure_summary
```

### SSH to Web Server
```bash
ssh -i your-key.pem ec2-user@$(terraform output -raw web_server_public_ip)
```

### SSH to App Server via Bastion
```bash
ssh -i your-key.pem -J ec2-user@$(terraform output -raw bastion_host_public_ip) ec2-user@$(terraform output -raw app_server_private_ip)
```

### Test Web Server
```bash
curl http://$(terraform output -raw web_server_public_ip)
```

## 📈 Cost Considerations

**Estimated Monthly Cost (us-west-2):**
- Web Server (t2.micro): ~$8.50
- App Server (t2.small): ~$17.00
- DB Server (t2.medium): ~$34.00
- Bastion (t2.micro): ~$8.50
- **Total:** ~$68/month

**Free Tier:**
- t2.micro: 750 hours/month free (first 12 months)
- Can run 2 instances 24/7 for free

## 🚨 Important Notes

1. **Security Groups:** Create separate SGs for each tier before deployment
2. **NAT Gateway:** Required for private instances to access internet (additional cost ~$32/month)
3. **Key Pair:** Must exist in AWS before deployment
4. **Private Subnet:** Ensure proper routing for private instances

## 🔄 Cleanup

```bash
terraform destroy
# Type 'yes' to confirm
```

## 📚 Comparison with Other Projects

| Feature | ec2-project | multi-instance-modules |
|---------|-------------|------------------------|
| Instances | 1 | 4 (Web, App, DB, Bastion) |
| Module Usage | Single instance | Multiple instances |
| Architecture | Simple | Multi-tier (3-tier + bastion) |
| Purpose | Basic module demo | Advanced module reusability |
| Subnets | 1 subnet | Public + Private |
| Learning Focus | Module basics | Module scalability |

## 🎯 Real-World Applications

This pattern is perfect for:
- ✅ Multi-tier web applications
- ✅ Development/Staging/Production environments
- ✅ Microservices architecture
- ✅ High-availability setups
- ✅ Enterprise applications

## 🔗 Next Steps

- Add Auto Scaling Groups
- Implement Application Load Balancer
- Add RDS instead of DB server
- Set up CloudWatch monitoring
- Implement backup strategies
- Add CI/CD pipeline integration

## 📖 Additional Resources

- [Terraform Modules Documentation](https://www.terraform.io/docs/language/modules/)
- [AWS Multi-Tier Architecture](https://docs.aws.amazon.com/whitepapers/latest/web-application-hosting-best-practices/an-aws-cloud-architecture-for-web-hosting.html)
- [Bastion Host Best Practices](https://aws.amazon.com/blogs/security/how-to-record-ssh-sessions-established-through-a-bastion-host/)

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
