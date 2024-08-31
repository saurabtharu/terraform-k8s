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
resource "aws_route_table" "k8s_setup_route_table" {
  vpc_id = aws_vpc.k8s_setup_vpc.id 

  route {
    cidr_block = "0.0.0.0/0"     /* to allow traffic from anywhere */
    gateway_id = aws_internet_gateway.k8s_setup_igw.id
  }

  tags = {
    Name = "K8s Setup Route Table"
  }
}


## 5. associate route table to the subnet setup
/* creating association of previously created route table with subnet*/

resource "aws_route_table_association" "k8s_setup_route_association" {
  subnet_id      = aws_subnet.k8s_setup_subnet.id
  route_table_id = aws_route_table.k8s_setup_route_table.id
}

## 6. security groups setup




###################################
#  Ansbile RELATED RESOURCES SETUP
###################################
