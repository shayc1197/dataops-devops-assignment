output "vpc_id" {
  value       = module.networking.vpc_id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = module.networking.vpc_cidr
  description = "VPC CIDR block"
}

output "public_subnet_ids" {
  value       = module.networking.public_subnet_ids
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = module.networking.private_subnet_ids
  description = "Private subnet IDs"
}

output "igw_id" {
  value       = module.networking.igw_id
  description = "Internet Gateway ID"
}

output "nat_gateway_id" {
  value       = module.networking.nat_gateway_id
  description = "NAT Gateway ID"
}

output "public_route_table_id" {
  value       = module.networking.public_route_table_id
  description = "Public route table ID"
}

output "private_route_table_id" {
  value       = module.networking.private_route_table_id
  description = "Private route table ID"
}



output "database_module_status" {
  value       = module.database.status
  description = "Implementation status of the database module"
}

output "kafka_module_status" {
  value       = module.kafka.status
  description = "Implementation status of the kafka module"
}

output "s3tables_module_status" {
  value       = module.s3tables.status
  description = "Implementation status of the s3tables module"
}
