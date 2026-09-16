# Complete AWS Infrastructure with Terraform

This project creates a complete AWS infrastructure from scratch including VPC, Subnet, Internet Gateway, Security Group, and EC2 instance. State is managed remotely in S3.

## Architecture

This Terraform configuration creates:

```
├── VPC (10.0.0.0/16)
│   ├── Public Subnet (10.0.1.0/24)
│   ├── Internet Gateway
│   └── Route Table (routes to IGW)
├── Security Group
│   ├── Inbound: SSH (22), HTTP (80), HTTPS (443)
│   └── Outbound: All traffic
└── EC2 Instance
    ├── Amazon Linux 2023
    ├── Apache Web Server (auto-installed)
    └── Public IP assigned
```

## Prerequisites

1. **Terraform** installed (>= 1.0)
2. **AWS CLI** configured with named profile
3. **S3 Bucket** for state storage
4. **Existing Key Pair** in AWS (create if needed)

### Create Key Pair (if you don't have one)

**Using AWS CLI:**
```powershell
aws ec2 create-key-pair --key-name ostad-batch-08 --query 'KeyMaterial' --output text --profile sarowar-ostad > ostad-batch-08.pem
```

**Or via AWS Console:**
1. Go to EC2 → Key Pairs
2. Create Key Pair
3. Download the `.pem` file

## Project Structure

```
complete-infrastructure/
├── main.tf                       # Root config with S3 backend
├── variables.tf                  # Input variables
├── outputs.tf                    # Output values
├── terraform.tfvars.example      # Example configuration
├── .gitignore
└── modules/
    ├── vpc/
    │   ├── main.tf              # VPC, Subnet, IGW, Route Table
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security-group/
    │   ├── main.tf              # Security Group with rules
    │   ├── variables.tf
    │   └── outputs.tf
    └── ec2/
        ├── main.tf              # EC2 instance with user data
        ├── variables.tf
        └── outputs.tf
```

## Setup Instructions

### Step 1: Create S3 Bucket for State

```powershell
# Create bucket
aws s3 mb s3://your-terraform-state-bucket --region us-west-2 --profile sarowar-ostad

# Enable versioning
aws s3api put-bucket-versioning `
  --bucket your-terraform-state-bucket `
  --versioning-configuration Status=Enabled `
  --profile sarowar-ostad

# Enable encryption
aws s3api put-bucket-encryption `
  --bucket your-terraform-state-bucket `
  --server-side-encryption-configuration '{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}' `
  --profile sarowar-ostad
```

### Step 2: Update Backend Configuration

Edit [main.tf](main.tf) and update the backend block:

```hcl
backend "s3" {
  bucket  = "your-actual-bucket-name"  # Change this
  key     = "complete-infrastructure/terraform.tfstate"
  region  = "us-west-2"
  encrypt = true
  profile = "sarowar-ostad"  # Change this
}
```

### Step 3: Configure Variables

```powershell
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_profile = "sarowar-ostad"
aws_region  = "us-west-2"

vpc_name = "my-terraform-vpc"
vpc_cidr = "10.0.0.0/16"

security_group_name = "my-ec2-sg"
allowed_ssh_cidr    = ["YOUR-IP/32"]  # Restrict SSH to your IP

instance_name = "my-ec2-instance"
ami_id        = "ami-00f46ccd1cbfb363e"
instance_type = "t2.micro"
key_name      = "ostad-batch-08"  # Your key pair name
```

### Step 4: Initialize and Deploy

```powershell
# Navigate to project directory
cd complete-infrastructure

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Create infrastructure
terraform apply

# Type 'yes' when prompted
```

### Step 5: Access Your Instance

After successful deployment, Terraform outputs:

```
instance_public_ip = "3.x.x.x"
ssh_connection_string = "ssh -i ostad-batch-08.pem ec2-user@3.x.x.x"
```

**SSH into the instance:**
```powershell
ssh -i ostad-batch-08.pem ec2-user@<public-ip>
```

**Test the web server:**
```powershell
# Open browser and navigate to:
http://<public-ip>
```

You should see a welcome page showing instance details!

## What Gets Created

### 1. VPC Module
- **VPC**: 10.0.0.0/16 CIDR block
- **Public Subnet**: 10.0.1.0/24 in first AZ
- **Internet Gateway**: For internet access
- **Route Table**: Routes public subnet traffic to IGW

### 2. Security Group Module
- **SSH (22)**: From specified CIDR
- **HTTP (80)**: From specified CIDR
- **HTTPS (443)**: From specified CIDR
- **Outbound**: All traffic allowed

### 3. EC2 Module
- **Instance**: Based on specified AMI and type
- **Apache Web Server**: Auto-installed via user data
- **Public IP**: Automatically assigned
- **Root Volume**: 8 GB GP3

## Important Variables

| Variable | Description | Example |
|----------|-------------|---------|
| aws_profile | AWS named profile | "sarowar-ostad" |
| aws_region | AWS region | "us-west-2" |
| vpc_cidr | VPC CIDR block | "10.0.0.0/16" |
| key_name | Existing key pair name | "ostad-batch-08" |
| allowed_ssh_cidr | IPs allowed for SSH | ["YOUR-IP/32"] |
| ami_id | AMI ID for EC2 | "ami-00f46ccd1cbfb363e" |

## Security Best Practices

✅ **SSH Access**: Restrict `allowed_ssh_cidr` to your IP only  
✅ **Key Pair**: Use existing key pair (user-defined)  
✅ **AWS Profile**: Uses named profile (no hardcoded credentials)  
✅ **State File**: Encrypted in S3 with versioning  
✅ **Security Groups**: Minimal required access  

## Outputs

After deployment, you'll get:

```hcl
vpc_id                 = "vpc-xxxxx"
public_subnet_id       = "subnet-xxxxx"
security_group_id      = "sg-xxxxx"
instance_id            = "i-xxxxx"
instance_public_ip     = "3.x.x.x"
instance_private_ip    = "10.0.1.x"
ssh_connection_string  = "ssh -i key.pem ec2-user@3.x.x.x"
```

## Managing Resources

### View Current State
```powershell
terraform show
```

### View Outputs
```powershell
terraform output
```

### Update Infrastructure
```powershell
# Modify variables or modules
terraform plan
terraform apply
```

### Destroy Everything
```powershell
terraform destroy
# Type 'yes' to confirm
```

## Cost Considerations

**Free Tier Eligible:**
- t2.micro EC2 instance (750 hours/month)
- 30 GB EBS storage
- 15 GB data transfer out

**Paid Resources:**
- S3 storage (minimal cost)
- Data transfer over limits

## Troubleshooting

**Error: "InvalidKeyPair.NotFound"**
- Ensure key pair exists in AWS in the specified region
- Create key pair or update `key_name` variable

**Error: "Error acquiring the state lock"**
- Another Terraform operation is running
- State file is being accessed by someone else

**Error: "UnauthorizedOperation"**
- Check IAM permissions for your AWS profile
- Ensure you have permissions to create VPC, EC2, SG

**Cannot SSH into instance:**
- Check security group allows SSH from your IP
- Verify key pair permissions: `chmod 400 key.pem`
- Ensure instance is in "running" state

**Website not accessible:**
- Wait 2-3 minutes for user data script to complete
- Check security group allows HTTP (port 80)
- Verify Apache is running: `sudo systemctl status httpd`

## AMI IDs by Region

| Region | AMI ID | Description |
|--------|--------|-------------|
| us-east-1 | ami-0c55b159cbfafe1f0 | Amazon Linux 2023 |
| us-west-2 | ami-00f46ccd1cbfb363e | Amazon Linux 2023 |
| eu-west-1 | ami-0c1c30571d2dae5c9 | Amazon Linux 2023 |

Find latest AMIs: [AWS AMI Catalog](https://console.aws.amazon.com/ec2/home#AMICatalog)

## Comparison with Other Projects

| Feature | first-ec2-example | ec2-project | ec2-project-s3-backend | complete-infrastructure |
|---------|------------------|-------------|------------------------|------------------------|
| VPC | ❌ Uses default | ✅ User-provided | ✅ User-provided | ✅ Creates new |
| Subnet | ❌ Default | ✅ User-provided | ✅ User-provided | ✅ Creates new |
| Security Group | ❌ Default | ✅ User-provided | ✅ User-provided | ✅ Creates new |
| State Backend | Local | Local | S3 | S3 |
| Credentials | Hardcoded | Named Profile | Named Profile | Named Profile |
| Modules | ❌ No | ✅ Yes | ✅ Yes | ✅ Yes |
| Production Ready | ❌ No | ⚠️ Partial | ✅ Yes | ✅ Yes |

## Next Steps

- Add private subnet for database tier
- Implement Auto Scaling Group
- Add Application Load Balancer
- Set up CloudWatch monitoring
- Configure S3 lifecycle policies
- Add state locking with DynamoDB
- Implement multiple environments using workspaces
- Add NAT Gateway for private subnet access

## Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform Modules](https://www.terraform.io/docs/language/modules/)

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
