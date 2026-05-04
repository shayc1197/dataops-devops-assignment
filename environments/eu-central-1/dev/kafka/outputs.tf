output "kafka_instance_private_ip" {
  value       = module.kafka.kafka_instance_private_ip
  description = "Private IP of Kafka EC2 instance"
}

output "kafka_sg_id" {
  value       = module.kafka.kafka_sg_id
  description = "Security Group ID for Kafka EC2"
}

output "kafka_instance_id" {
  value       = module.kafka.kafka_instance_id
  description = "ID of Kafka EC2 instance"
}

output "kafka_instance_profile_name" {
  value       = module.kafka.kafka_instance_profile_name
  description = "IAM Instance Profile name for Kafka EC2"
}

output "table_bucket_arn" {
  value       = module.s3tables.table_bucket_arn
  description = "ARN of the S3 Tables bucket"
}

output "orders_table_arn" {
  value       = module.s3tables.orders_table_arn
  description = "ARN of the orders Iceberg table"
}
