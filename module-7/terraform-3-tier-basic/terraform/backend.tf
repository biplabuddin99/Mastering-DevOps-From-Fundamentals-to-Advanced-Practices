# S3 Backend Configuration for Terraform State
# This backend stores the Terraform state in an S3 bucket
# Before running terraform init, ensure the S3 bucket exists

terraform {
  backend "s3" {
    bucket  = "batch09-ostad"  # Change this to your bucket name
    key     = "bmi-app/terraform.tfstate"
    region  = "ap-south-1"                  # Change to your region
    profile = "sarowar-ostad"                     # Change to your AWS profile name
    
    # Enable encryption
    encrypt = true
    
    # Note: DynamoDB table is not used (as per requirements)
  }
}
