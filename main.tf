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
/*
four security groups 
1. Allow SSH and HTTP(S)
2. k8s control plane
3. k8s worker nodes 
4. Flannel UDP ports
*/


// 1. common ports (ssh, http, https)
resource "aws_security_group" "k8s_setup_sg_common" {
  name = "k8s_setup_sg_common"
  tags = {
    Name: "K8s Setup Common Security Group"
  }


  // inbound rules
  ingress {
    description = "Allow HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "Allow HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // outbound rules
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/24"]
  }
}


// 2. control plane ports
resource "aws_security_group" "k8s_setup_sg_control_plane" {
  name = "k8s_setup_sg_control_plane"
  tags = {
    Name: "K8s Setup Security Group : Control Plane"
  }
  
  ingress {
    description = "Kubernetes API server"
    from_port = 6443
    to_port = 6443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubelet API"
    from_port = 10250
    to_port = 10250
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "kube-scheduler"
    from_port = 10259
    to_port = 10259
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "kube-controller-manager"
    from_port = 10257
    to_port = 10257
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "etcd server client API"
    from_port = 2379
    to_port = 2380
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// 3. data plane ports
resource "aws_security_group" "k8s_setup_sg_data_plane" {

  name = "k8s_setup_sg_data_plane"
  tags = {
    Name: "K8s Setup Security Group : Data Plane"
  }

  ingress {
    description = "Kubelet API"
    from_port = 10250
    to_port = 10250
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "kube-proxy"
    from_port = 10256
    to_port = 10256
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort Services"
    from_port = 30000
    to_port = 32767
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// 4. flannel UDP ports
  
resource "aws_security_group" "k8s_setup_sg_flannel" {
  name = "k8s_setup_sg_flannel"
  tags = {
    Name = "K8s Setup Security Group : Flannel"
  }

  ingress {
    description = "UDP Backend"
    from_port = 8285
    to_port = 8285
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "UDP vxlan backend"
    from_port = 8472
    to_port = 8472
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###################################
#  Ansbile RELATED RESOURCES SETUP
###################################
