#list available Availability ones in a region/ This is needed for creating subnets and further requirements.
data "aws_availability_zones" "available" {
  state = "available"
}
