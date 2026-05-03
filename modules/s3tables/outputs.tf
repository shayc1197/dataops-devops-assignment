output "status" {
  value       = local.module_status
  description = "Current implementation status of the s3tables module"
}

output "table_bucket_arn" {
  value       = local.enabled ? aws_s3tables_table_bucket.iceberg[0].arn : ""
  description = "ARN of the S3 Tables bucket"
}

output "table_bucket_name" {
  value       = local.enabled ? aws_s3tables_table_bucket.iceberg[0].name : ""
  description = "Name of the S3 Tables bucket"
}

output "orders_table_arn" {
  value       = local.enabled ? aws_s3tables_table.orders[0].arn : ""
  description = "ARN of the orders Iceberg table"
}