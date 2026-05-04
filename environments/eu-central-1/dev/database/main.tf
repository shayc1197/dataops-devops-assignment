
module "database" {
  source = "../../../../modules/database"

  enabled            = true
  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  name_prefix        = local.name_prefix
  tags               = local.tags
  vpc_cidr           = local.vpc_cidr
  ssm_s3_bucket      = local.ssm_s3_bucket
}