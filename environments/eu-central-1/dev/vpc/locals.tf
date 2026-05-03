locals {
  name_prefix = "dataops-pipeline-dev-eu-central-1"

  tags = {
    Project     = "dataops-pipeline"
    Environment = "dev"
    Region      = "eu-central-1"
    ManagedBy   = "terraform"
  }

  # VPC Configuration
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["eu-central-1a", "eu-central-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true

  # SSM S3 bucket for Ansible file transfers (used by community.aws.aws_ssm connection plugin)
  ssm_s3_bucket = "terraform-state-shayc-eu-central-1"

  # External IP fetched automatically via data.external.my_ip
  admin_external_cidr = data.external.my_ip.result.ip
}
