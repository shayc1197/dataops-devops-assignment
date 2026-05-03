provider "aws" {
  region = "eu-central-1"

  assume_role {
    role_arn = "arn:aws:iam::039806193116:role/TerraformAdminRole"
  }

  default_tags {
    tags = local.tags
  }
}
