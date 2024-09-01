terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.5"
    }
    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
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



#######################
#   KEY PAIR
#######################

resource "tls_private_key" "k8s_setup_private_key" {
  algorithm =  "RSA"
  rsa_bits  = 4096

  provisioner "local-exec" {
    command = "echo '${self.public_key_pem}' > ./pubkey.pem"
  }
}

resource "aws_key_pair" "k8s_setup_key_pair" {
  key_name = var.key_pair_name
  public_key = tls_private_key.k8s_setup_private_key.public_key_openssh


  provisioner "local-exec" {
    command = "echo '${tls_private_key.k8s_setup_private_key.private_key_pem}' > ./private-key.pem"
  }
}



#########################
#  INSTANCES SETUP
#########################

resource "aws_instance" "k8s-control-plane" {
  ami      = var.rhel_ami
  instance_type = "t2.medium"

  key_name = aws_key_pair.k8s_setup_key_pair.key_name
  associate_public_ip_address = true
  security_groups = [
    aws_security_group.k8s_setup_sg_common.name,
    aws_security_group.k8s_setup_sg_control_plane.name,
    aws_security_group.k8s_setup_sg_flannel.name
  ]

  root_block_device {
    volume_size = 14
    volume_type = "gp2"
  }

  tags = {
    Name = "K8s Control Plane"
    Role = "Control Plane"
  }

  provisioner "local-exec" {
    command = "echo 'master ${self.public_ip}' >> ./files/hosts"
  }
}



resource "aws_instance" "k8s-data-plane" {
  count = var.data_plane_count
  ami = var.rhel_ami
  instance_type = var.k8s_setup_instance_type

  key_name = aws_key_pair.k8s_setup_key_pair.key_name
  associate_public_ip_address = true
  
  security_groups = [
    aws_security_group.k8s_setup_sg_common.name,
    aws_security_group.k8s_setup_sg_data_plane.name,
    aws_security_group.k8s_setup_sg_flannel.name
  ]

  tags = {
    Name = "K8s Data Plane - ${count.index}"
    Role = "Data Plane"
  }
   
  provisioner "local-exec" {
    command = "echo 'worker-${count.index} ${self.public_ip}' >> ./files/hosts"
  }
}





###################################
#  Ansbile RELATED RESOURCES SETUP
###################################
resource "ansible_host" "k8s_setup_master_node" {
  depends_on = [ 
    aws_instance.k8s-control-plane
  ]

  name = "control-plane"
  groups = ["master"]
  variables = {
    ansible_user = "ec2-user"
    ansible_host = aws_instance.k8s-control-plane.public_ip
    ansible_ssh_private_key_file = "./private-key.pem"
    node_hostname = "master"
  }
}

resource "ansible_host" "k8s_setup_worker_node" {
  depends_on = [ 
    aws_instance.k8s-data-plane
  ]

  count = 2
  name = "worker-${count.index}"
  groups = ["workers"]
  variables = {
    ansible_user = "ec2-user"
    ansible_host = aws_instance.k8s-data-plane[count.index].public_ip
    ansible_ssh_private_key_file = "./private-key.pem"
    node_hostname = "worker-${count.index}"
  }
}
