data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket  = "terraform-state-shayc-eu-central-1"
    key     = "eu-central-1/dev/vpc/terraform.tfstate"
    region  = "eu-central-1"

    assume_role = {
      role_arn = "arn:aws:iam::039806193116:role/TerraformAdminRole"
    }
  }
}
