terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # ==========================================================
  # Backend (S3 state with native locking — no DynamoDB)
  # ==========================================================
  backend "s3" {
    bucket  = "terraform-state-shayc-eu-central-1"
    key     = "eu-central-1/dev/vpc/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true

    assume_role = {
      role_arn = "arn:aws:iam::039806193116:role/TerraformAdminRole"
    }
  }
}
