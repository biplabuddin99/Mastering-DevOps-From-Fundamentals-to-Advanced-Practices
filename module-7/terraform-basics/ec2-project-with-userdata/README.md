# AWS EC2 Terraform Module

This Terraform configuration creates an AWS EC2 instance using a modular approach with local state management.

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with named profiles
- Existing AWS resources (VPC, Subnet, Security Group)

## Project Structure

```
ec2-project/
├── main.tf                  # Root module configuration
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

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars` with your values:**
   ```hcl
   aws_profile = "your-profile-name"
   aws_region  = "us-east-1"
   
   instance_name = "my-ec2-instance"
   ami_id        = "ami-0c55b159cbfafe1f0"
   instance_type = "t2.micro"
   
   vpc_id            = "vpc-12345678"
   subnet_id         = "subnet-12345678"
   security_group_id = "sg-12345678"
   
   key_name = "my-key-pair"
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Review the plan:**
   ```bash
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```

6. **Destroy resources when done:**
   ```bash
   terraform destroy
   ```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_profile | AWS named profile | string | "default" | yes |
| aws_region | AWS region | string | "us-east-1" | yes |
| instance_name | Name for the EC2 instance | string | - | yes |
| ami_id | AMI ID | string | - | yes |
| instance_type | Instance type | string | "t2.micro" | no |
| vpc_id | VPC ID | string | - | yes |
| subnet_id | Subnet ID | string | - | yes |
| security_group_id | Security Group ID | string | - | yes |
| key_name | Key pair name | string | "" | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | EC2 instance ID |
| instance_public_ip | Public IP address |
| instance_private_ip | Private IP address |
| instance_state | Current state of the instance |

## State Management

This configuration uses **local state file** (`terraform.tfstate`). The state file is stored locally and should NOT be committed to version control.

For production use, consider using remote state backends like:
- AWS S3 with DynamoDB for state locking
- Terraform Cloud
- Other supported backends

## Notes

- The state file contains sensitive information and is gitignored
- Ensure your AWS credentials are properly configured
- The security group should allow necessary inbound/outbound traffic
- The subnet should have appropriate route table associations

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
