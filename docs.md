
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

### 2. Subnet 


```hcl
## 2. Subnet 
resource "aws_subnet" "k8s_setup_subnet" {
  vpc_id     = aws_vpc.k8s_setup_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s_setup_subnet"
  }  
}
```


`$ terraform plan`
`$ terraform apply -auto-aprove`


### 3. internet gateway


```hcl
## 3. internet gateway /* allow VPC to connect to internet  */
resource "aws_internet_gateway" "k8s_setup_igw" {
  vpc_id = aws_vpc.k8s_setup_vpc.id

  tags = {
    Name = "k8s_setup_igw"
  }

}

```

`$ terraform plan`
`$ terraform apply -auto-aprove`

