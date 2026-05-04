locals {
  enabled     = true
  name_prefix = "dataops-pipeline-dev-eu-central-1"
  tags = {
    Project     = "dataops-pipeline"
    Environment = "dev"
    Region      = "eu-central-1"
    ManagedBy   = "terraform"
  }
}
