#basic project name and region:
variable "project" {
  default     = "zomato"
  description = "project name"
}
variable "environment" {
  default     = "production"
  description = "project environment"
}
variable "region" {
  default     = "us-east-2"
  description = "region at which this is implemented"
}

# Access credentials of the IAM user having privileges
variable "access_key" {
  default     = "*****************"
  description = "my access key"
}
variable "secret_key" {
  default     = "*****************"
  description = "my secret key"
}

# details of instances to be launched
variable "instance_ami" {
  default = "ami-0a606d8395a538502"
}
variable "instance_type" {
  default = "t2.micro"
}

#Number of availability zones which are available to create subnets, common tags to be attached
locals {
  subnets = length(data.aws_availability_zones.available.names)
  common_tags = {
    "project"     = var.project
    "environemnt" = var.environment
  }
}

# declaring CIDR range
variable "network" {
  type    = string
  default = "172.16.0.0/16"
}

#Private zone name
variable "privzone" {
  default = "hashmi.local"
}

#domain hosted in route53
variable "maindomain" {
  default = "haashdev.tech"
}

#variables for dbsetup.sh and wpinstall.sh

variable "db_user" {
  default = "wpuser"
}

variable "db_password" {
  default = "wp123"
}

variable "db_name" {
  default = "wpdb"
}
locals {
  dbhost = "db.${var.privzone}"
}

# Public IPs from which access can be granted.
variable "public_access" {
  type = list(string)
  default = [
    "157.46.153.42/32",
    "157.46.153.43/32",
    "157.46.153.45/32",
    "65.2.30.232/32"
  ]
}

# SSH access restrictions
variable "public_ssh_to_frontend" {
  default = false
}

variable "public_ssh_to_backend" {
  default = false
}

#Ports used
variable "backend_port" {
  type    = number
  default = 3306
}

variable "bastion_port" {
  type    = number
  default = 22
}

variable "frontend_ports" {
  type    = list(string)
  default = ["80", "443", "8080"]
}
