# Terraform Project for Kubernetes Cluster Setup on AWS


## Prerequisite Tool

- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#pipx-install) 
- [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## Usage

configure `aws` cli

Command: `aws configure`

```bash
user@my-computer ~/g/terraform-k8s (main)> aws configure
AWS Access Key ID [****************UF4V]: *************
AWS Secret Access Key [****************tsmw]: *********************************** 
Default region name [us-east-1]:
Default output format [json]:
```

```bash
# Install terraform module
terraform init

# See what resources will be created in aws
terraform plan

# create directory to store collection of nodes and IP address
mkdir -p files

# Apply the terraform file
terraform apply

# Change the permission for the private key so that ssh can be done
chmod 600 private-key.pem

# Use ansible to create setup k8s cluster
ansible-playbook -i inventory.yml playbook.yml
```
