# Module: Database (PostgreSQL/MySQL with CDC enabled)
# Placeholder for implementation – TODO: EC2 + Database setup + Debezium configuration

variable "enabled" {
  description = "When true, provision the CDC source database instance and related resources"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID from networking module"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "Private subnet IDs from networking module"
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

variable "vpc_cidr" {
  description = "VPC CIDR block (for ingress rules from Kafka)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ssm_s3_bucket" {
  description = "S3 bucket name for Ansible SSM connection file transfers"
  type        = string
}

locals {
  module_status = var.enabled ? "deploying" : "placeholder"
}

# Security Group for Database EC2
resource "aws_security_group" "database" {
  count           = var.enabled ? 1 : 0
  name_prefix     = "db-"
  description     = "Security group for Database EC2"
  vpc_id          = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-sg"
  })
}

# PostgreSQL from Kafka Debezium (via VPC CIDR)
resource "aws_security_group_rule" "database_postgres_from_kafka" {
  count             = var.enabled ? 1 : 0
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.database[0].id
  description       = "PostgreSQL from Kafka Debezium via VPC"
}

# Outbound - All traffic
resource "aws_security_group_rule" "database_egress" {
  count             = var.enabled ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.database[0].id
  description       = "All outbound traffic"
}

# IAM Role for Database EC2 Instance
resource "aws_iam_role" "database" {
  count           = var.enabled ? 1 : 0
  name_prefix     = "db-ec2-"
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

# IAM Policy for S3 access (backups, logs)
resource "aws_iam_role_policy" "database_s3" {
  count  = var.enabled ? 1 : 0
  name   = "${var.name_prefix}-db-s3"
  role   = aws_iam_role.database[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.name_prefix}-*/*"
      },
      {
        Sid    = "S3BucketList"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.name_prefix}-*"
      }
    ]
  })
}

# IAM Policy for Secrets Manager access (database credentials)
resource "aws_iam_role_policy" "database_secrets" {
  count  = var.enabled ? 1 : 0
  name   = "${var.name_prefix}-db-secrets"
  role   = aws_iam_role.database[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.name_prefix}/*"
      }
    ]
  })
}

# SSM Managed Instance Core policy (no SSH needed - access via SSM Session Manager)
resource "aws_iam_role_policy_attachment" "database_ssm" {
  count      = var.enabled ? 1 : 0
  role       = aws_iam_role.database[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile for Database EC2
resource "aws_iam_instance_profile" "database" {
  count       = var.enabled ? 1 : 0
  name_prefix = "db-ec2-"
  role        = aws_iam_role.database[0].name
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

# EC2 Instance for PostgreSQL CDC Source
resource "aws_instance" "database" {
  count                    = var.enabled ? 1 : 0
  ami                      = data.aws_ami.ubuntu.id
  instance_type            = "t3.micro"
  subnet_id                = var.private_subnet_ids[0]
  iam_instance_profile     = aws_iam_instance_profile.database[0].name
  vpc_security_group_ids   = [aws_security_group.database[0].id]
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database"
  })

  depends_on = [aws_security_group.database]
}

# Provisioner: Wait for SSM agent and run Ansible via SSM
resource "null_resource" "ansible_provisioner" {
  count = var.enabled ? 1 : 0

  # Wait for SSM agent to register
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for SSM agent on ${aws_instance.database[0].id}..."
      until aws ssm describe-instance-information \
        --filters "Key=InstanceIds,Values=${aws_instance.database[0].id}" \
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
        -i "${aws_instance.database[0].id}," \
        -e "ansible_connection=community.aws.aws_ssm" \
        -e "ansible_aws_ssm_region=eu-central-1" \
        -e "ansible_aws_ssm_bucket_name=${var.ssm_s3_bucket}" \
        -e "ansible_python_interpreter=/usr/bin/python3" \
        -vvv \
        "${path.module}/ansible/playbooks/install_postgresql.yml"
    EOT

    environment = {
      AWS_PROFILE        = "terraform"
      AWS_DEFAULT_REGION = "eu-central-1"
    }
  }

  depends_on = [aws_instance.database]
}