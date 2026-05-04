locals {
  name_prefix = "dataops-pipeline-dev-eu-central-1"

  tags = {
    Project     = "dataops-pipeline"
    Environment = "dev"
    Region      = "eu-central-1"
    ManagedBy   = "terraform"
  }

  vpc_cidr      = "10.0.0.0/16"
  ssm_s3_bucket = "terraform-state-shayc-eu-central-1"

  # External IP fetched automatically via data.external.my_ip
  admin_external_cidr = data.external.my_ip.result.ip
}
