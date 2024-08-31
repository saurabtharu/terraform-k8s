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
## 2. Subnet setup
## 3. internet gateway setup
## 4. custom route table setup
## 5. associate route table to the subnet setup
## 6. security groups setup




###################################
#  Ansbile RELATED RESOURCES SETUP
###################################
