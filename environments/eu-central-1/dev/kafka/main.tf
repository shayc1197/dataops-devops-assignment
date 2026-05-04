module "kafka" {
  source = "../../../../modules/kafka"

  enabled                    = true
  vpc_id                     = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnet_ids         = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  name_prefix                = local.name_prefix
  tags                       = local.tags
  database_private_ip        = data.terraform_remote_state.database.outputs.database_instance_private_ip
  vpc_cidr                   = local.vpc_cidr
  control_center_cidr_blocks = [local.admin_external_cidr]
  ssm_s3_bucket              = local.ssm_s3_bucket
  s3tables_table_bucket_arn  = module.s3tables.table_bucket_arn
  aws_region                 = "eu-central-1"

  depends_on = [module.s3tables]
}

module "s3tables" {
  source = "../../../../modules/s3tables"
}
