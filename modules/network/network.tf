variable "prefix" {}

locals {
  az_quantity = 2
}

data "aws_availability_zones" "available" {}

# Resources
# --------------------------------------------------------------------

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = var.prefix
  }
}

resource "aws_subnet" "public_subnets" {
  count = local.az_quantity

  availability_zone = data.aws_availability_zones.available.names[count.index]

  # Divides cidr_block into sub blocks equal to the difference in netmasks.
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, local.az_quantity + count.index)
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-public"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.prefix
  }
}

resource "aws_route" "internet_access" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
  route_table_id         = aws_vpc.vpc.main_route_table_id
}

resource "aws_security_group" "security_group" {
  description = "Prevent inbound traffic"
  name        = var.prefix
  vpc_id      = aws_vpc.vpc.id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

# Outputs
# --------------------------------------------------------------------

output "security_group" {
  value = aws_security_group.security_group.id
}

output "subnets" {
  value = [for subnet in aws_subnet.public_subnets : "${subnet.id}"]
}
