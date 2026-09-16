# First EC2 Instance with Terraform

A simple example to create your first AWS EC2 instance using Terraform.

## Installing Terraform

### Windows

**Option 1: Using Chocolatey**
```powershell
choco install terraform
```

**Option 2: Manual Installation**
1. Download Terraform from: https://www.terraform.io/downloads
2. Extract the `.zip` file
3. Move `terraform.exe` to a directory in your PATH (e.g., `C:\terraform`)
4. Add the directory to your system PATH:
   - Open System Properties → Advanced → Environment Variables
   - Edit the `Path` variable and add `C:\terraform`
5. Verify installation:
   ```powershell
   terraform --version
   ```

### Linux (Ubuntu/Debian)
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### macOS
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

## Prerequisites

- Terraform installed
- AWS account
- AWS Access Key and Secret Key

## Setup

1. **Edit the configuration file:**
   Open `first_ec2.tf` and replace the placeholder values:
   ```hcl
   access_key = "YOUR-ACTUAL-ACCESS-KEY"
   secret_key = "YOUR-ACTUAL-SECRET-KEY"
   ```

2. **Verify the AMI ID:**
   Make sure the AMI ID (`ami-00c39f71452c08778`) is available in your region (us-east-1)

## Commands

### 1. Initialize Terraform
```powershell
terraform init
```
This downloads the AWS provider plugin and initializes the working directory.

### 2. Preview Changes
```powershell
terraform plan
```
This shows what Terraform will create without actually making changes.

### 3. Create Resources
```powershell
terraform apply
```
Type `yes` when prompted to create the EC2 instance.

### 4. Destroy Resources (when done)
```powershell
terraform destroy
```
Type `yes` when prompted to delete the EC2 instance.

## What This Does

- Creates a single EC2 instance in the `us-east-1` region
- Uses Amazon Linux 2 AMI (check if AMI ID is valid for your region)
- Instance type: `t2.micro` (Free tier eligible)
- Uses hardcoded AWS credentials (⚠️ NOT recommended for production)

## Important Security Notes

⚠️ **WARNING**: This example uses hardcoded credentials for learning purposes only!

**For production, use one of these methods instead:**
- AWS Named Profiles (recommended)
- IAM Roles (for EC2 instances)
- Environment variables
- AWS SSO

**Never commit AWS credentials to version control!**

## File Structure

```
first-ec2-example/
├── first_ec2.tf    # Main Terraform configuration
└── README.md       # This file
```

## Expected Output

After `terraform apply`, you should see:
- The EC2 instance ID
- The instance will appear in your AWS Console under EC2

## Troubleshooting

**Error: "No valid credential sources found"**
- Double-check your access_key and secret_key

**Error: "InvalidAMIID.NotFound"**
- The AMI ID might not exist in us-east-1
- Find a valid AMI ID in AWS Console → EC2 → Launch Instance

**Error: "UnauthorizedOperation"**
- Your IAM user needs `ec2:RunInstances` permission

## Next Steps

After testing this basic example, check out the `ec2-project` folder for a more production-ready setup using:
- AWS Named Profiles
- Terraform Modules
- Existing VPC/Subnet/Security Groups
- Better security practices

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
