output "database_instance_private_ip" {
  value       = module.database.database_instance_private_ip
  description = "Private IP of Database EC2 instance"
}

output "database_sg_id" {
  value       = module.database.database_sg_id
  description = "Security Group ID for Database EC2"
}

output "database_instance_id" {
  value       = module.database.database_instance_id
  description = "ID of Database EC2 instance"
}

output "database_instance_profile_name" {
  value       = module.database.database_instance_profile_name
  description = "IAM Instance Profile name for Database EC2"
}
