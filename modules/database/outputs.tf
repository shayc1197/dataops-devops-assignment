output "status" {
  value       = local.module_status
  description = "Current implementation status of the database module"
}

output "database_sg_id" {
  value       = try(aws_security_group.database[0].id, "")
  description = "Security Group ID for Database EC2"
}

output "database_instance_profile_name" {
  value       = try(aws_iam_instance_profile.database[0].name, "")
  description = "IAM Instance Profile name for Database EC2"
}

output "database_instance_private_ip" {
  value       = try(aws_instance.database[0].private_ip, "")
  description = "Private IP of Database EC2 instance"
}

output "database_instance_id" {
  value       = try(aws_instance.database[0].id, "")
  description = "ID of Database EC2 instance"
}