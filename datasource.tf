#List available availability zones in a region
data "aws_availability_zones" "available" {
  state = "available"
}

# Fetching hosted zone of the domain mentioned in variables.tf, in route53
data "aws_route53_zone" "mydomain" {
  name         = var.maindomain
  private_zone = false
}

# Fetching the userdata files as templates with "path module"
data "template_file" "backend" {
  template = file("${path.module}/dbsetup.sh")
  vars = {
    DB_NAME     = var.db_name
    DB_USER     = var.db_user
    DB_PASSWORD = var.db_password
  }
}


data "template_file" "frontend" {
  template = file("${path.module}/wpinstall.sh")
  vars = {
    DB_NAME     = var.db_name
    DB_USER     = var.db_user
    DB_PASSWORD = var.db_password
    DBHOST      = local.dbhost
  }
}
