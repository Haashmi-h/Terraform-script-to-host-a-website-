#Invoking new VPC module from the path where it is located. I have saved the module in "/var/vpc-module/"
  module "vpc" {
  source      = "/var/vpc-module/"
  project     = var.project
  environment = var.environment
  network     = var.network

}





#security_groups

resource "aws_ec2_managed_prefix_list" "public_access_prefix" {

  name           = "${var.project}-${var.environment}-prefix"
  address_family = "IPv4"
  max_entries    = length(var.public_access)

  dynamic "entry" {

    for_each = var.public_access
    iterator = item

    content {
      cidr = item.value
    }
  }

  tags = {
    Name = "${var.project}-${var.environment}-prefix"
  }
}

#For bastion server    
resource "aws_security_group" "sg-bastion" {
  vpc_id      = module.vpc.vpc_id
  name_prefix = "${var.project}-${var.environment}-bastion"
  description = "Allow SSH traffic to frontend and backend servers"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    prefix_list_ids = [aws_ec2_managed_prefix_list.public_access_prefix.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  lifecycle {
    # Necessary if changing 'name' or 'name_prefix' properties.
    create_before_destroy = true
  }
  tags = {
    "Name" = "${var.project}-${var.environment}-bastion"
  }
}
  
#For frontend server  
resource "aws_security_group" "sg-frontend" {
  vpc_id      = module.vpc.vpc_id
  name_prefix = "${var.project}-${var.environment}-frontend"
  description = "Allow HTTPS and HTTP from all, 22 from bastion"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = var.public_ssh_to_frontend == true ? ["0.0.0.0/0"] : null
    security_groups = [aws_security_group.sg-bastion.id]
  }

  dynamic "ingress" {
    for_each = toset(var.frontend_ports)
    iterator = port
    content {
      from_port        = port.value
      to_port          = port.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "${var.project}-${var.environment}-frontend"
  }
  lifecycle {
    # Necessary if changing 'name' or 'name_prefix' properties.
    create_before_destroy = true
  }
}

#For backend server
resource "aws_security_group" "sg-backend" {
  vpc_id      = module.vpc.vpc_id
  name_prefix = "${var.project}-${var.environment}-backend"
  description = "Allow 22 from bastion, 3306 from frontend"

  ingress {
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-frontend.id]
  }

  ingress {
    from_port       = var.bastion_port
    to_port         = var.bastion_port
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-bastion.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    # Necessary if changing 'name' or 'name_prefix' properties.
    create_before_destroy = true
  }
  tags = {
    "Name" = "${var.project}-${var.environment}-backend"
  }
}

#Importing a key
resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.project}-${var.environment}"
  public_key = file("mykey.pub")
  tags = {
    "Name" = "${var.project}-${var.environment}"
  }
}


# For launching instances from the above resources
resource "aws_instance" "bastion" {
  instance_type          = var.instance_type
  ami                    = var.instance_ami
  subnet_id              = module.vpc.public_subnets.0
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.sg-bastion.id]
  tags = {
    "Name" = "${var.project}-${var.environment}-bastion"
  }
}
resource "aws_instance" "frontend" {
  instance_type               = var.instance_type
  ami                         = var.instance_ami
  subnet_id                   = module.vpc.public_subnets.1
  key_name                    = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids      = [aws_security_group.sg-frontend.id]
  user_data                   = data.template_file.frontend.rendered
  user_data_replace_on_change = true
  depends_on                  = [aws_instance.backend]
  tags = {
    "Name" = "${var.project}-${var.environment}-frontend"
  }
}
resource "aws_instance" "backend" {
  depends_on                  = [module.vpc]
  subnet_id                   = module.vpc.private_subnets.0
  instance_type               = var.instance_type
  ami                         = var.instance_ami
  key_name                    = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids      = [aws_security_group.sg-backend.id]
  user_data                   = data.template_file.backend.rendered
  user_data_replace_on_change = true
  tags = {
    "Name" = "${var.project}-${var.environment}-backend"
  }
}

# Creating a private zone and record for database host in Route53
resource "aws_route53_zone" "private" {
  name = var.privzone
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}
resource "aws_route53_record" "backend" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "db.${var.privzone}"
  type    = "A"
  ttl     = 5
  records = [aws_instance.backend.private_ip]
}
  
#Creating new public subdomain in Route53
resource "aws_route53_record" "wpdomain" {
  zone_id = data.aws_route53_zone.mydomain.id
  name    = "wordpress.${var.maindomain}"
  type    = "A"
  ttl     = 5
  records = [aws_instance.frontend.public_ip]
}
