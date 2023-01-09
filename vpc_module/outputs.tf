# Outputs to be listed and passed on to project directory
output "vpc_id" {
  value = aws_vpc.vpc.id
}


output "public_subnets" {

  value = aws_subnet.public[*].id
}

output "private_subnets" {

  value = aws_subnet.private[*].id
}
