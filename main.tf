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




#########################
#  NETWORKING SETUP
#########################

## 1. custom VPC setup
resource "aws_vpc" "k8s_setup_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true

  tags = {
    Name = "K8s Setup VPC"
  }
}


## 2. Subnet setup
resource "aws_subnet" "k8s_setup_subnet" {
  vpc_id     = aws_vpc.k8s_setup_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "K8s Setup Subnet"
  }  
}



## 3. internet gateway setup /* allow VPC to connect to internet  */
resource "aws_internet_gateway" "k8s_setup_igw" {
  vpc_id = aws_vpc.k8s_setup_vpc.id

  tags = {
    Name = "K8s Setup Internet Gateway"
  }

}

## 4. custom route table setup
## 5. associate route table to the subnet setup
## 6. security groups setup




###################################
#  Ansbile RELATED RESOURCES SETUP
###################################
