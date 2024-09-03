# output "public_ip_master" {
#     description = "Public IP address of the master node"
#     value = aws_instance.k8s-control-plane.public_ip
# }
# 
# 
# output "public_ips_data_plane" {
#   description = "List of public IP addresses for the data plane instances"
#   value = [for instance in aws_instance.k8s-data-plane : instance.public_ip]
# }
