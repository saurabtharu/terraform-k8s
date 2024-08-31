
# Automating the setup of k8s in AWS with kubeadm using terraform and ansible


## Step 1: Create files for terraform

- `main.tf`
- `variables.tf`
- `outputs.tf`


## Step 2: Get setup aws provider

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
```

`$ terraform init`

This command will download the `hashicorp/aws` module of terraform


## Step 3: Setting up Networking Infrastructure

### 1. custom VPC setup

```hcl
## 1. custom VPC 
resource "aws_vpc" "k8s_setup_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true

  tags = {
    Name = "k8s_setup_vpc"
  }
}
```


`$ terraform plan`
`$ terraform apply -auto-aprove`

