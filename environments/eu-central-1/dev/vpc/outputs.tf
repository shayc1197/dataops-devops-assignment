output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = module.vpc.vpc_cidr
  description = "VPC CIDR block"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "Private subnet IDs"
}

output "igw_id" {
  value       = module.vpc.igw_id
  description = "Internet Gateway ID"
}

output "nat_gateway_id" {
  value       = module.vpc.nat_gateway_id
  description = "NAT Gateway ID"
}

output "public_route_table_id" {
  value       = module.vpc.public_route_table_id
  description = "Public route table ID"
}

output "private_route_table_id" {
  value       = module.vpc.private_route_table_id
  description = "Private route table ID"
}
