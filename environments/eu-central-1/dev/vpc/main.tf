# Fetch current machine's external IP automatically on every plan/apply
data "external" "my_ip" {
  program = ["bash", "-c", "echo \"{\\\"ip\\\": \\\"$(curl -s ifconfig.me)/32\\\"}\""]
}

check "subnet_list_lengths" {
  assert {
    condition = length(local.azs) == length(local.public_subnet_cidrs) && length(local.azs) == length(local.private_subnet_cidrs)

    error_message = "azs, public_subnet_cidrs, and private_subnet_cidrs must contain the same number of entries."
  }
}

module "networking" {
  source = "../../../../modules/networking"

  name_prefix          = local.name_prefix
  tags                 = local.tags
  vpc_cidr             = local.vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  enable_dns_hostnames = local.enable_dns_hostnames
  enable_dns_support   = local.enable_dns_support
}

module "database" {
  source = "../../../../modules/database"

  enabled            = true
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  name_prefix        = local.name_prefix
  tags               = local.tags
  vpc_cidr           = local.vpc_cidr
  ssm_s3_bucket      = local.ssm_s3_bucket
}

module "kafka" {
  source = "../../../../modules/kafka"

  enabled                    = true
  vpc_id                     = module.networking.vpc_id
  private_subnet_ids         = module.networking.private_subnet_ids
  name_prefix                = local.name_prefix
  tags                       = local.tags
  database_private_ip        = module.database.database_instance_private_ip
  vpc_cidr                   = local.vpc_cidr
  control_center_cidr_blocks = [local.admin_external_cidr]
  ssm_s3_bucket              = local.ssm_s3_bucket
  s3tables_table_bucket_arn  = module.s3tables.table_bucket_arn
  aws_region                 = "eu-central-1"

  depends_on = [module.database, module.s3tables]
}

module "s3tables" {
  source = "../../../../modules/s3tables"
}
