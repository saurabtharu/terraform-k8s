
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

`$ terraform init` <br>

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


`$ terraform plan` <br>
`$ terraform apply -auto-aprove` <br>

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


`$ terraform plan` <br>
`$ terraform apply -auto-aprove` <br>


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

`$ terraform plan` <br>
`$ terraform apply -auto-approve` <br>

### 4. custom route table

```hcl

## 4. custom route table
resource "aws_route_table" "k8s_setup_route_table" {
  vpc_id = aws_vpc.k8s_setup_vpc.id

  route {
    cidr_block = "0.0.0.0/0"     /* to allow traffic from anywhere */
    gateway_id = aws_internet_gateway.k8s_setup_igw.id
  }

  tags = {
    Name = "example"
  }
}
```

`$ terraform plan` <br>
`$ terraform apply -auto-approve` <br>


### 5. associate route table to the subnet

```hcl
/* creating association of previously created route table with subnet*/

resource "aws_route_table_association" "k8s_setup_route_association" {
  subnet_id      = aws_subnet.k8s_setup_subnet.id
  route_table_id = aws_route_table.k8s_setup_route_table.id
}
```
`$ terraform plan` <br>
`$ terraform apply -auto-approve` <br>


### 6. security groups 

#### I. common ports (ssh, http, https)
```hcl

resource "aws_security_group" "k8s_setup_sg_common" {
  name = "k8s_setup_sg_common"
  tags = {
    Name: "k8s_setup_sg_common"
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
```

`$ terraform plan` <br>
`$ terraform apply -auto-approve` <br>


#### II. control plane ports

```hcl
resource "aws_security_group" "k8s_setup_sg_control_plane" {
  name = "k8s_setup_sg_control_plane"
  tags = {
    Name: "k8s_setup_sg_control_plane"
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
```

`$ terraform plan` <br>
`$ terraform apply -auto-approve` <br>



#### IV. flannel UDP ports

```hcl
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
```

`$ terraform plan` <br>
`$ terraform apply -auto-approve` <br>




## Step 4: Create Key Pair resource


### install `hashicorp/tls` provider by adding below code in `terraform > required_providers` block as below 

```diff
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
+    tls = {
+      source = "hashicorp/tls"
+      version = "4.0.5"
+    }
  }
}
```
also add following in file `variables.tf`

```hcl
variable "key_pair_name" {
  type = string
  description = "Name of key pair"
  default = "setup_key"
}
```

add `tls_private_key` in file `main.tf`.

```hcl
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
```


## Step 5: Setting up EC2 instance in AWS 


### For master-node (`control-plane`)

```hcl
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
```

here variables `rhel_ami` is used so add following in `variables.tf`

```hcl
variable "rhel_ami" {
  type = string
  description = "ami id for EC2 instance"
  default = "ami-0583d8c7a9c35822c"
}
```


### For worker-node (`data-plane`)

```hcl
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
```

since, new variables `data_plane_count` and `k8s_setup_instance_type` are used declare them in `variables.tf` file as below

```hcl
variable "data_plane_count" {
  type = number
  description = "The number of worker nodes (data plane) in cluster"
  default = 2

}

variable "k8s_setup_instance_type" {
  type = string
  description = "Value for EC2 instance type "
  default = "t2.micro"

}
```
