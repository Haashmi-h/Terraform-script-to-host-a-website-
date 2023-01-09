#Defining new VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.network
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

#Defining new internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

#Defining 2 public subnets
resource "aws_subnet" "public" {
  count                   = local.subnets - 1
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.network, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${var.environment}-public${count.index + 1}"
  }
}


#Defining 1 private subnet
resource "aws_subnet" "private" {
  count                   = local.subnets - 2
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false
  cidr_block              = cidrsubnet(var.network, 4, "${count.index + 2}")
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.project}-${var.environment}-private${count.index + 1}"
  }
}

#Creating elastic IP
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0
vpc = true
  tags = {
    Name = "${var.project}-${var.environment}-natgw"
  }
}

#Creating NATgateway
resource "aws_nat_gateway" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat.0.id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = "${var.project}-${var.environment}"
  }
  depends_on = [aws_internet_gateway.igw]
}

#Creating public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.project}-${var.environment}-public"
  }
}

#Creating private route table
resource "aws_route_table" "private" {

  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.project}-${var.environment}-private"
  }
}
resource "aws_route" "enable_nat" {
  count = var.enable_nat_gateway ? 1 : 0
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.nat.0.id
  depends_on                = [ aws_route_table.private]
}

#Routetable associations
resource "aws_route_table_association" "public" {
  count          = local.subnets - 1
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = local.subnets - 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
