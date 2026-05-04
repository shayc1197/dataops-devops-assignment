# DataOps CDC Pipeline on AWS

This repository provisions and validates an end-to-end Change Data Capture pipeline on AWS with Terraform, PostgreSQL, Confluent Kafka, Debezium, and S3 Tables backed by Iceberg.

The pipeline implemented in this repo is:

```text
PostgreSQL on EC2
  -> Debezium source connector
  -> Kafka topic cdc.orders
  -> Iceberg sink connector
  -> AWS S3 Tables / Iceberg table default.orders
```

## What This Project Does

The environment provisions a private VPC, launches a PostgreSQL source instance, launches a Kafka/Connect instance with Confluent Community components, creates an S3 Tables Iceberg table, and wires the CDC flow so inserts into `public.orders` are published to Kafka and written into Iceberg.

At a high level:

- Terraform creates the AWS infrastructure.
- Ansible assets inside the Terraform modules configure PostgreSQL and Kafka Connect.
- Debezium captures row changes from PostgreSQL.
- Kafka Connect sink writes those CDC events into the Iceberg table `default.orders`.

## Architecture

```text
AWS eu-central-1

VPC
  -> private subnets
  -> PostgreSQL EC2 instance
  -> Kafka / Kafka Connect / Control Center EC2 instance

PostgreSQL public.orders
  -> Debezium PostgresConnector
  -> Kafka topic cdc.orders
  -> IcebergSinkConnector
  -> S3 Tables bucket
  -> Iceberg table default.orders
```

## Repository Structure

```text
terraform-aws-project/
├── environments/
│   └── eu-central-1/
│       └── dev/
│           ├── vpc/                  # Root Terraform stack for networking
│           ├── database/             # Root Terraform stack for PostgreSQL
│           └── kafka/                # Root Terraform stack for Kafka + S3 Tables
├── modules/
│   ├── vpc/                          # VPC, subnets, routing
│   ├── database/                     # PostgreSQL EC2 + provisioning assets
│   ├── kafka/                        # Kafka EC2 + Confluent + connectors
│   └── s3tables/                     # S3 Tables bucket, namespace, Iceberg table
├── ansible-labs/                     # Separate Ansible learning material / labs
├── terraform.tfstate                 # Local state artifact in this workspace
└── README.md
```

## How The Terraform Is Organized

The environment is split into three Terraform root stacks under `environments/eu-central-1/dev/`:

- `vpc`: Creates the VPC and subnet layout by calling `modules/vpc`.
- `database`: Provisions the PostgreSQL EC2 instance by calling `modules/database` and reading the VPC outputs from remote state.
- `kafka`: Provisions the Kafka EC2 instance and S3 Tables resources by calling `modules/kafka` and `modules/s3tables`, while reading the VPC and database outputs from remote state.

Important implementation details:

- Each directory has its own backend key and Terraform state in S3.
- The stacks must be applied in order: `vpc` -> `database` -> `kafka`.
- Database and Kafka provisioning rely on bundled Ansible assets under `modules/database/ansible` and `modules/kafka/ansible`.
- Ansible runs automatically during `terraform apply` for the database and kafka stacks.

## Prerequisites

You need the following installed locally:

```bash
terraform -version
aws --version
session-manager-plugin --version
ansible --version
jq --version
```

Example installation on Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install -y jq
```

You also need:

- AWS credentials with permission to create VPC, EC2, IAM, S3, and S3 Tables resources.
- Access to `eu-central-1`.
- An AWS CLI profile if you do not want to use the default profile.

## Deployment

Apply the three stacks one by one, in dependency order.

### 1. Deploy the VPC

```bash
cd environments/eu-central-1/dev/vpc
terraform init
terraform apply
```

### 2. Deploy the database

```bash
cd environments/eu-central-1/dev/database
terraform init
terraform apply
```

This stack reads the VPC outputs from remote state and runs the PostgreSQL Ansible provisioning automatically.

### 3. Deploy Kafka and S3 Tables

```bash
cd environments/eu-central-1/dev/kafka
terraform init
terraform apply
```

This stack reads the VPC and database outputs from remote state and runs the Kafka/Connect Ansible provisioning automatically.

## What Gets Created

After a successful apply, the environment should include:

- A VPC and private subnets.
- A PostgreSQL EC2 instance configured for CDC.
- A Kafka EC2 instance running Confluent components.
- Kafka Connect connectors:
  - `debezium-postgres-orders`
  - `iceberg-sink-orders`
- Kafka topic `cdc.orders`.
- S3 Tables bucket and Iceberg table `default.orders`.

## Ansible Execution

You do not need to run Ansible manually during the normal deployment flow.

- `terraform apply` in `database/` creates the EC2 instance and then runs the PostgreSQL playbook.
- `terraform apply` in `kafka/` creates the EC2 instance and then runs the Kafka/Connect playbook.
- If a provisioner fails, re-running `terraform apply` in the same stack is the first thing to try.

## End-to-End Validation

Use the checks below to prove the pipeline is working.

### 1. Verify the sink connector is running

```bash
curl -s http://127.0.0.1:8083/connectors/iceberg-sink-orders/status | jq
```

Expected:

- connector state is `RUNNING`
- task state is `RUNNING`

### 2. Verify the Debezium source connector is running

```bash
curl -s http://127.0.0.1:8083/connectors/debezium-postgres-orders/status | jq
```

Expected:

- connector state is `RUNNING`
- task state is `RUNNING`

### 3. Verify CDC events exist in Kafka

Run on the Kafka host:

```bash
/opt/confluent/bin/kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic cdc.orders \
  --from-beginning \
  --max-messages 5 \
  --timeout-ms 5000
```

Expected:

- JSON CDC messages from Debezium
- rows such as `Charlie` and `David`
- decimal values serialized correctly, for example `"300.00"`

### 4. Verify the Iceberg table exists in S3 Tables

```bash
aws s3tables get-table --profile terraform --region eu-central-1 \
  --table-bucket-arn arn:aws:s3tables:eu-central-1:039806193116:bucket/dataops-pipeline-dev-eu-central-1-iceberg-tables \
  --namespace default \
  --name orders
```

Expected:

- `name` is `orders`
- `namespace` is `default`
- `format` is `ICEBERG`
- output contains `metadataLocation` and `warehouseLocation`

## Optional UI Validation

To view Confluent Control Center locally, forward port `9021` through SSM:

```bash
aws ssm start-session --profile terraform --region eu-central-1 \
  --target i-003e6528444385d2f \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["9021"],"localPortNumber":["9021"]}'
```

Then open:

```text
http://127.0.0.1:9021
```

Useful UI proof points:

- `iceberg-sink-orders` shows `RUNNING`
- `debezium-postgres-orders` shows `RUNNING`

## Suggested Submission Evidence

If this repo is being used for a home assignment or demo, the minimal screenshot set is:

1. Control Center page showing `iceberg-sink-orders` in `RUNNING` state.
2. Kafka Connect status output showing both source and sink connectors in `RUNNING` state.
3. Kafka consumer output showing CDC events in `cdc.orders`.
4. `aws s3tables get-table` output proving `default.orders` exists as an Iceberg table.

Recommended screenshot captions:

- `Iceberg sink connector (iceberg-sink-orders) is running successfully`
- `Kafka Connect status verification: both source and sink connectors are running`
- `Kafka topic cdc.orders contains CDC events from PostgreSQL`
- `S3 Tables verification: default.orders exists as an Iceberg table`

## Notes About The Current Repo

There are a few important details to understand when reading this codebase:

- The current README previously described an older repository layout that does not match the actual folders in this workspace.
- The active environment is split across `environments/eu-central-1/dev/vpc`, `environments/eu-central-1/dev/database`, and `environments/eu-central-1/dev/kafka`.
- The Kafka Ansible tasks include the connector deployment logic and the Debezium TLS key conversion required for PostgreSQL SSL authentication.
- The S3 Tables module defines the Iceberg schema for `orders`, including CDC metadata columns such as `__op` and `__source_ts`.

## Troubleshooting

If validation fails, start here:

- Check Terraform outputs from the relevant stack directory.
- Apply the stacks in order: `vpc` -> `database` -> `kafka`.
- If Ansible provisioning fails, rerun `terraform apply` from the same stack directory.
- Check Kafka Connect status via the REST API on port `8083`.
- Check Control Center via the forwarded `9021` port.
- Check the Kafka topic with `kafka-console-consumer`.
- Check the Iceberg table definition with `aws s3tables get-table`.

Useful Terraform commands:

```bash
cd environments/eu-central-1/dev/vpc
terraform validate
terraform plan
terraform output
```

Useful state inspection commands:

```bash
terraform state list
terraform state show module.kafka.aws_instance.kafka[0]
```

## Summary

This repository provisions a working CDC pipeline where PostgreSQL changes are captured by Debezium, published into Kafka, and persisted into an Iceberg table in AWS S3 Tables. The most important operational checks are connector health, Kafka topic contents, and the final Iceberg table definition.
