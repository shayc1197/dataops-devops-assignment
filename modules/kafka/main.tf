# Module: Kafka (Confluent Platform Community Edition)
# Placeholder for implementation – TODO: EC2 + Confluent install + connectors

variable "enabled" {
  description = "When true, provision the Confluent Platform instance and related resources"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID from networking module"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Kafka broker"
  type        = list(string)
  default     = []
}

variable "name_prefix" {
  description = "Resource naming prefix"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "database_sg_id" {
  description = "Security Group ID of Database module (for ingress rules)"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "VPC CIDR block (for ingress from VPC)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ssm_s3_bucket" {
  description = "S3 bucket name for Ansible SSM connection file transfers"
  type        = string
}

variable "database_private_ip" {
  description = "Private IP of Database EC2 instance (for Debezium connector configuration)"
  type        = string
  default     = ""
}

variable "control_center_cidr_blocks" {
  description = "CIDR blocks allowed to access Confluent Control Center (port 9021)"
  type        = list(string)
  default     = []
}

variable "s3tables_table_bucket_arn" {
  description = "ARN of the S3 Tables bucket used by the Iceberg sink connector"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region for S3 Tables and connector configuration"
  type        = string
  default     = "eu-central-1"
}

locals {
  module_status = var.enabled ? "deploying" : "placeholder"
}

# Security Group for Kafka EC2
resource "aws_security_group" "kafka" {
  count           = var.enabled ? 1 : 0
  name_prefix     = "kafka-"
  description     = "Security group for Kafka EC2"
  vpc_id          = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-kafka-sg"
  })
}

# Kafka Broker from Database Debezium (via VPC CIDR)
resource "aws_security_group_rule" "kafka_broker_from_database" {
  count             = var.enabled ? 1 : 0
  type              = "ingress"
  from_port         = 9092
  to_port           = 9092
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.kafka[0].id
  description       = "Kafka broker from Database Debezium via VPC"
}

# Kafka Connect REST API from VPC
resource "aws_security_group_rule" "kafka_connect_from_vpc" {
  count             = var.enabled ? 1 : 0
  type              = "ingress"
  from_port         = 8083
  to_port           = 8083
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.kafka[0].id
  description       = "Kafka Connect REST API from VPC"
}

# Control Center UI from external admin IP
resource "aws_security_group_rule" "kafka_control_center_from_vpc" {
  count             = var.enabled && length(var.control_center_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = 9021
  to_port           = 9021
  protocol          = "tcp"
  cidr_blocks       = var.control_center_cidr_blocks
  security_group_id = aws_security_group.kafka[0].id
  description       = "Control Center UI from admin external IP"
}

# Outbound - All traffic
resource "aws_security_group_rule" "kafka_egress" {
  count             = var.enabled ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kafka[0].id
  description       = "All outbound traffic"
}

# IAM Role for Kafka EC2 Instance
resource "aws_iam_role" "kafka" {
  count           = var.enabled ? 1 : 0
  name_prefix     = "kafka-ec2-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for S3 access (Iceberg sink connector writes to S3)
resource "aws_iam_role_policy" "kafka_s3" {
  count  = var.enabled ? 1 : 0
  name   = "${var.name_prefix}-kafka-s3"
  role   = aws_iam_role.kafka[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3TablesBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.name_prefix}-*/*"
      },
      {
        Sid    = "S3TablesBucketList"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.name_prefix}-*"
      }
    ]
  })
}

# IAM Policy for S3 Tables API access (if using AWS S3 Tables)
resource "aws_iam_role_policy" "kafka_s3tables" {
  count  = var.enabled ? 1 : 0
  name   = "${var.name_prefix}-kafka-s3tables"
  role   = aws_iam_role.kafka[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3TablesAccess"
        Effect = "Allow"
        Action = [
          "s3tables:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# SSM Managed Instance Core policy (no SSH needed - access via SSM Session Manager)
resource "aws_iam_role_policy_attachment" "kafka_ssm" {
  count      = var.enabled ? 1 : 0
  role       = aws_iam_role.kafka[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile for Kafka EC2
resource "aws_iam_instance_profile" "kafka" {
  count       = var.enabled ? 1 : 0
  name_prefix = "kafka-ec2-"
  role        = aws_iam_role.kafka[0].name
}

# Data source: Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance for Kafka
resource "aws_instance" "kafka" {
  count                    = var.enabled ? 1 : 0
  ami                      = data.aws_ami.ubuntu.id
  instance_type            = "t3.medium"
  subnet_id                = var.private_subnet_ids[0]
  iam_instance_profile     = aws_iam_instance_profile.kafka[0].name
  vpc_security_group_ids   = [aws_security_group.kafka[0].id]
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  user_data_base64 = base64encode(templatefile("${path.module}/templates/kafka-user-data.sh.tftpl", {
  }))

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-kafka"
  })

  depends_on = [aws_security_group_rule.kafka_broker_from_database]
}

# Provisioner: Wait for SSM agent and run Ansible via SSM
resource "null_resource" "ansible_provisioner" {
  count = var.enabled ? 1 : 0

  # Wait for SSM agent to register
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for SSM agent on ${aws_instance.kafka[0].id}..."
      until aws ssm describe-instance-information \
        --filters "Key=InstanceIds,Values=${aws_instance.kafka[0].id}" \
        --query 'length(InstanceInformationList)' \
        --output text 2>/dev/null | grep -q "^1"; do
        echo "SSM agent not ready, retrying in 15s..."
        sleep 15
      done
      echo "SSM agent ready."
    EOT

    environment = {
      AWS_PROFILE        = "terraform"
      AWS_DEFAULT_REGION = "eu-central-1"
    }
  }

  # Run Ansible playbook via SSM
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      # Install community.aws collection if not already installed
      ansible-galaxy collection list community.aws 2>/dev/null | grep -q 'community\.aws' || \
        ansible-galaxy collection install community.aws
      # Install boto3 if not present (required for community.aws SSM connection)
      python3 -c "import boto3" 2>/dev/null || pip3 install boto3 -q

      if ! command -v session-manager-plugin >/dev/null 2>&1; then
        echo "session-manager-plugin is required on the machine running Terraform." >&2
        echo "Install it before running terraform apply to avoid an interactive sudo prompt inside local-exec." >&2
        exit 1
      fi

      ansible-playbook \
        -i "${aws_instance.kafka[0].id}," \
        -e "ansible_connection=community.aws.aws_ssm" \
        -e "ansible_aws_ssm_region=eu-central-1" \
        -e "ansible_aws_ssm_bucket_name=${var.ssm_s3_bucket}" \
        -e "ansible_python_interpreter=/usr/bin/python3" \
        -e "database_private_ip=${var.database_private_ip}" \
        -e "s3tables_table_bucket_arn=${var.s3tables_table_bucket_arn}" \
        -e "aws_region=${var.aws_region}" \
        -vvv \
        "${path.module}/ansible/playbooks/install_confluent.yml"
    EOT

    environment = {
      AWS_PROFILE        = "terraform"
      AWS_DEFAULT_REGION = var.aws_region
    }
  }

  depends_on = [aws_instance.kafka]
}

# IMPLEMENTATION ROADMAP:
# 1. EC2 Instance (t3.large, Ubuntu 22.04 LTS with Docker)
# 2. Security Groups (inbound: 9092 from Database EC2, 8083 from anywhere VPC, 9021 from anywhere VPC)
# 3. IAM Instance Profile (S3 access for Iceberg sink connector)
# 4. Confluent Platform Installation
#    - Kafka Broker (port 9092)
#    - Schema Registry (port 8081)
#    - Kafka Connect (port 8083)
#    - Control Center (port 9021)
# 5. Topic Creation: cdc.orders (3 partitions, RF=1)
# 6. Debezium PostgreSQL Connector (REST API call to Kafka Connect)
# 7. Iceberg Kafka Connect Sink Connector (tabular-io/iceberg-kafka-connect)