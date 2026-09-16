# AWS EC2 Terraform Module with S3 Backend

This Terraform configuration creates an AWS EC2 instance using a modular approach with **S3 remote state management**.

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with named profiles
- Existing AWS resources:
  - VPC, Subnet, Security Group
  - S3 bucket for state storage

## S3 Backend Setup

### Step 1: Create S3 Bucket for State Storage

You can create the S3 bucket using AWS CLI or console:

**Using AWS CLI:**
```bash
aws s3 mb s3://your-terraform-state-bucket --region us-west-2 --profile sarowar-ostad
```

**Enable versioning (recommended):**
```bash
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled \
  --profile sarowar-ostad
```

**Enable encryption (recommended):**
```bash
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
  --profile sarowar-ostad
```

### Step 2: Update Backend Configuration

Edit `main.tf` and update the backend configuration:

```hcl
backend "s3" {
  bucket  = "your-actual-bucket-name"
  key     = "ec2-project/terraform.tfstate"
  region  = "us-west-2"
  encrypt = true
  profile = "your-aws-profile"
}
```

## Project Structure

```
ec2-project-s3-backend/
├── main.tf                  # Root module with S3 backend config
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── terraform.tfvars.example # Example values
├── .gitignore              # Git ignore rules
└── modules/
    └── ec2/
        ├── main.tf         # EC2 module resources
        ├── variables.tf    # Module variables
        └── outputs.tf      # Module outputs
```

## Usage

### 1. Copy the example variables file:
```powershell
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit `terraform.tfvars` with your values:
```hcl
aws_profile = "sarowar-ostad"
aws_region  = "us-west-2"

instance_name = "my-ec2-instance"
ami_id        = "ami-00f46ccd1cbfb363e"
instance_type = "t3.medium"

vpc_id            = "vpc-02f7c57975d04ca56"
subnet_id         = "subnet-03672544009e3c40e"
security_group_id = "sg-07cc5ad28f68e8e55"

key_name = "ostad-batch-08"
```

### 3. Edit `main.tf` backend configuration:
Update the S3 bucket name and other backend settings.

### 4. Initialize Terraform (downloads providers & configures backend):
```powershell
terraform init
```

### 5. Review the plan:
```powershell
terraform plan
```

### 6. Apply the configuration:
```powershell
terraform apply
```

### 7. Destroy resources when done:
```powershell
terraform destroy
```

## Backend Configuration Details

### S3 Backend Parameters

| Parameter | Description | Required |
|-----------|-------------|----------|
| bucket | S3 bucket name for state storage | Yes |
| key | Path within the bucket | Yes |
| region | AWS region of the bucket | Yes |
| encrypt | Enable server-side encryption | Recommended |
| profile | AWS profile to use | Yes |

## Advantages of S3 Backend

✅ **Remote State Storage**: State file stored securely in S3
✅ **Team Collaboration**: Multiple team members can access the same state
✅ **Versioning**: Track state file history
✅ **Encryption**: Secure sensitive data at rest
✅ **Backup & Recovery**: S3 provides durability and versioning

## Important Notes

### Security Best Practices
- Enable S3 bucket versioning
- Enable S3 server-side encryption
- Use IAM policies to restrict bucket access
- Enable S3 bucket logging for audit trails
- Block public access to the S3 bucket

### Backend Migration
If migrating from local state to S3:
```powershell
# Backup your local state first
cp terraform.tfstate terraform.tfstate.backup

# Then run init with migration
terraform init -migrate-state
```

## IAM Permissions Required

Your AWS user/role needs these permissions:

**For S3 Backend:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::your-terraform-state-bucket",
        "arn:aws:s3:::your-terraform-state-bucket/*"
      ]
    }
  ]
}
```

## Troubleshooting

**Error: "Error loading state: AccessDenied"**
- Check your AWS credentials and IAM permissions
- Verify the S3 bucket exists and is accessible

## Comparing with Local Backend

| Feature | Local Backend | S3 Backend |
|---------|--------------|------------|
| State Location | Local file system | AWS S3 |
| Team Collaboration | ❌ Difficult | ✅ Easy |
| State Locking | ❌ No | ⚠️ No (requires DynamoDB) |
| Version History | ❌ Manual | ✅ Automatic |
| Backup/Recovery | ❌ Manual | ✅ Automatic |
| Security | ⚠️ Local only | ✅ Encrypted, auditable |

## Optional: Adding State Locking with DynamoDB

For team environments, you can add state locking to prevent concurrent modifications:

**1. Create DynamoDB table:**
```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-west-2 \
  --profile sarowar-ostad
```

**2. Add to backend configuration in main.tf:**
```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "ec2-project/terraform.tfstate"
  region         = "us-west-2"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"  # Add this line
  profile        = "sarowar-ostad"
}
```

**3. Re-initialize Terraform:**
```bash
terraform init -reconfigure
```

## Next Steps

- Set up S3 bucket lifecycle policies for old state versions
- Configure S3 bucket policies for team access
- Consider using Terraform workspaces for multiple environments
- Add DynamoDB state locking for team collaboration (see above)

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
