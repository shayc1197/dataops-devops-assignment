# Kafka Ansible Provisioning

## Overview
This directory contains Ansible playbooks and roles to automatically deploy and configure the Confluent Platform on the Kafka EC2 instance.

## Structure
```
ansible/
├── playbooks/
│   └── install_confluent.yml      # Main playbook
├── roles/
│   ├── confluent/                 # Confluent Platform installation
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml
│   │   └── templates/
│   │       ├── confluent-zookeeper.service.j2
│   │       ├── confluent-kafka.service.j2
│   │       ├── confluent-schema-registry.service.j2
│   │       ├── confluent-kafka-connect.service.j2
│   │       ├── confluent-control-center.service.j2
│   │       ├── server.properties.j2
│   │       └── connect-distributed.properties.j2
│   └── iceberg_connector/         # Iceberg sink connector
│       └── tasks/main.yml
```

## Prerequisites

### Local Machine (where Terraform runs)
- Ansible installed: `pip install ansible`
- SSH key generated: `ssh-keygen -t rsa -f ~/.ssh/id_rsa`
- SSH key added to EC2 instance (handled by Terraform via user_data)

### EC2 Instance
- Ubuntu 22.04 LTS AMI
- Python 3 installed (handled by user_data)
- SSH port (22) accessible from admin CIDR blocks

## Usage

### Automatic (via Terraform)
When you run `terraform apply` with `kafka.enabled = true`:
1. EC2 instance launches with minimal user_data
2. Terraform waits for SSH to be ready
3. Terraform automatically runs the Ansible playbook
4. Confluent Platform is fully installed and configured

```bash
# In environments/eu-central-1/dev/vpc/
terraform apply
```

### Manual
If you need to re-run Ansible after EC2 is already created:

```bash
# Get EC2 private IP from Terraform output
EC2_IP=$(terraform output -raw kafka_instance_private_ip)

# Run Ansible playbook
cd modules/kafka/ansible
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i "${EC2_IP}," \
  -u ubuntu \
  --private-key ~/.ssh/id_rsa \
  -v \
  playbooks/install_confluent.yml
```

## Playbook Details

### install_confluent.yml
Main orchestration playbook that:
1. Waits for EC2 to be fully ready
2. Updates system packages
3. Installs Java and dependencies
4. Runs `confluent` role to install Confluent Platform
5. Creates topic `cdc.orders` with 3 partitions
6. Runs `iceberg_connector` role to deploy Iceberg sink connector
7. Validates all services are running

### confluent role
- Creates `confluent` user and directories
- Downloads and extracts Confluent Platform 7.5.0
- Installs systemd services for:
  - Zookeeper
  - Kafka Broker
  - Schema Registry
  - Kafka Connect
  - Control Center
- Configures services with proper environment variables
- Starts all services

### iceberg_connector role
- Downloads Iceberg Kafka Connect Sink JAR
- Creates connector configuration
- Deploys connector via Kafka Connect REST API (port 8083)
- Validates connector is running

## Post-Deployment

### Access Confluent Components

**Control Center UI** (port 9021)
```
http://<EC2_PRIVATE_IP>:9021
```

**Kafka Broker** (port 9092)
```
<EC2_PRIVATE_IP>:9092
```

**Kafka Connect REST API** (port 8083)
```
http://<EC2_PRIVATE_IP>:8083/connectors
```

**Schema Registry** (port 8081)
```
http://<EC2_PRIVATE_IP>:8081
```

### Verify Installation

SSH into the instance:
```bash
ssh -i ~/.ssh/id_rsa ubuntu@<EC2_PRIVATE_IP>
```

Check service status:
```bash
systemctl status confluent-kafka
systemctl status confluent-connect
systemctl status confluent-control-center
```

List topics:
```bash
/opt/confluent/bin/kafka-topics --list --bootstrap-server localhost:9092
```

## Troubleshooting

### SSH Connection Issues
- Ensure security group allows inbound SSH (port 22) from admin CIDR
- Verify SSH key permissions: `chmod 600 ~/.ssh/id_rsa`
- Check EC2 instance status in AWS console

### Ansible Playbook Failures
- Check EC2 user_data logs: `/var/log/cloud-init-output.log`
- Re-run playbook with verbose output:
  ```bash
  ansible-playbook -vvv playbooks/install_confluent.yml
  ```

### Service Won't Start
- Check service logs:
  ```bash
  journalctl -u confluent-kafka -f
  ```
- Verify ports are not in use:
  ```bash
  netstat -tlnp | grep 9092
  ```

### Connector Deployment Failed
- Check Kafka Connect logs:
  ```bash
  tail -f /opt/confluent/logs/connect-distributed.log
  ```
- Verify Kafka Connect is running:
  ```bash
  curl http://localhost:8083/connector-plugins
  ```

## Configuration Customization

### Modify Confluent Version
Edit `install_confluent.yml` playbook:
```yaml
vars:
  confluent_version: "7.6.0"  # Change version
```

### Tune JVM Heap
Edit service templates in `roles/confluent/templates/`:
```bash
Environment="KAFKA_HEAP_OPTS=-Xms512M -Xmx2G"
```

### Configure Iceberg Connector
Edit `roles/iceberg_connector/tasks/main.yml` to customize:
- S3 bucket path
- Table namespace/name
- Connector topic
- Upsert mode and write format
