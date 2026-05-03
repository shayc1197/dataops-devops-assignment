output "status" {
  value       = local.module_status
  description = "Current implementation status of the kafka module"
}

output "kafka_sg_id" {
  value       = try(aws_security_group.kafka[0].id, "")
  description = "Security Group ID for Kafka EC2"
}

output "kafka_instance_profile_name" {
  value       = try(aws_iam_instance_profile.kafka[0].name, "")
  description = "IAM Instance Profile name for Kafka EC2"
}

output "kafka_instance_private_ip" {
  value       = try(aws_instance.kafka[0].private_ip, "")
  description = "Private IP of Kafka EC2 instance"
}

output "kafka_instance_id" {
  value       = try(aws_instance.kafka[0].id, "")
  description = "ID of Kafka EC2 instance"
}