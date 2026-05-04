# Module: S3 Tables (Iceberg)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}



locals {
  module_status = local.enabled ? "deploying" : "placeholder"
}


resource "aws_s3tables_table_bucket" "iceberg" {
  count = local.enabled ? 1 : 0
  name  = "${local.name_prefix}-iceberg-tables"
}

resource "aws_s3tables_namespace" "default" {
  count            = local.enabled ? 1 : 0
  table_bucket_arn = aws_s3tables_table_bucket.iceberg[0].arn
  namespace        = "default"
}

resource "aws_s3tables_table" "orders" {
  count            = local.enabled ? 1 : 0
  table_bucket_arn = aws_s3tables_table_bucket.iceberg[0].arn
  namespace        = aws_s3tables_namespace.default[0].namespace
  name             = "orders"
  format           = "ICEBERG"

  metadata {
    iceberg {
      schema {
        field {
          name     = "id"
          type     = "int"
          required = false
        }
        field {
          name     = "customer_name"
          type     = "string"
          required = false
        }
        field {
          name     = "amount"
          type     = "decimal(10,2)"
          required = false
        }
        field {
          name     = "status"
          type     = "string"
          required = false
        }
        field {
          name     = "created_at"
          type     = "timestamp"
          required = false
        }
        field {
          name     = "__op"
          type     = "string"
          required = false
        }
        field {
          name     = "__source_ts"
          type     = "long"
          required = false
        }
      }
    }
  }
}
