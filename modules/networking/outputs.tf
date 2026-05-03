output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = aws_vpc.this.cidr_block
  description = "VPC CIDR block"
}

output "public_subnet_ids" {
  value       = [for s in aws_subnet.public : s.id]
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = [for s in aws_subnet.private : s.id]
  description = "Private subnet IDs"
}

output "igw_id" {
  value       = aws_internet_gateway.this.id
  description = "Internet Gateway ID"
}

output "nat_gateway_id" {
  value       = aws_nat_gateway.this.id
  description = "NAT Gateway ID"
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Public route table ID"
}

output "private_route_table_id" {
  value       = aws_route_table.private.id
  description = "Private route table ID"
}

