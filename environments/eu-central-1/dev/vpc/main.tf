check "subnet_list_lengths" {
  assert {
    condition = length(local.azs) == length(local.public_subnet_cidrs) && length(local.azs) == length(local.private_subnet_cidrs)

    error_message = "azs, public_subnet_cidrs, and private_subnet_cidrs must contain the same number of entries."
  }
}

module "vpc" {
  source = "../../../../modules/vpc"

  name_prefix          = local.name_prefix
  tags                 = local.tags
  vpc_cidr             = local.vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  enable_dns_hostnames = local.enable_dns_hostnames
  enable_dns_support   = local.enable_dns_support
}