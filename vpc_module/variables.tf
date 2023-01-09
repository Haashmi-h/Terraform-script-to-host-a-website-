#No: of Subnets to be created from the available availability zones in a region.
locals {
  subnets = length(data.aws_availability_zones.available.names)
}

#Name and Tags
variable "project" {
  default = "demo"
}
variable "environment" {}

#CIDR range to be fetched from project directory
variable "network" {}

#boolean variable to enable NAT.
variable "enable_nat_gateway" {
  type = bool
  default = true
}
