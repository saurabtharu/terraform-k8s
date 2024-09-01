variable "key_pair_name" {
  type = string
  description = "Name of key pair"
  default = "setup_key"
}




variable "rhel_ami" {
  type = string
  description = "ami id for EC2 instance"
  default = "ami-0583d8c7a9c35822c"
}

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
