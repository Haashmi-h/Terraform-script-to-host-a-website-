output "vpc-module-return" {
  value = module.vpc
}
output "Frontend-public-ip" {
  value = aws_instance.frontend.public_ip
}
output "backend-private-ip" {
  value = aws_instance.backend.private_ip
}
output "bastion-public-ip" {
  value = aws_instance.bastion.public_ip
}
output "New_website" {
  value = "http://wordpress.${var.maindomain}"
}

output "Frontend_private_IP" {
  value = aws_instance.frontend.private_ip
}
