provider "aws" {
    region  = var.aws_region
    profile = var.aws_profile
}

#--- VPC ---

resource "aws_vpc" "eden_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags =  {
      Name = "eden_vpc"
  }

}

# Internet Gateway
resource "aws_internet_gateway" "eden_internet_gateway" {
    vpc_id = aws_vpc.eden_vpc.id 
    tags = {
        Name = "eden_igw"
    }
}


# Route tables
resource "aws_route_table" "eden_public_rt" {
  vpc_id = aws_vpc.eden_vpc.id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id =aws_internet_gateway.eden_internet_gateway.id
  }
  
  tags = {
      Name = "eden_public"
  }
}

resource "aws_default_route_table" "eden_private_rt" {
  default_route_table_id = aws_vpc.eden_vpc.default_route_table_id

  tags = {
      Name = "eden_private"
  }
}


# Subnets

resource "aws_subnet" "eden_public1_subnet" {
  vpc_id = aws_vpc.eden_vpc.id
  cidr_block = var.cidrs["public1"]
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "eden_public1"
  }
}
resource "aws_subnet" "eden_public2_subnet" {
  vpc_id = aws_vpc.eden_vpc.id
  cidr_block = var.cidrs["public2"]
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "eden_public2"
  }
}


resource "aws_subnet" "eden_private1_subnet" {
  vpc_id = aws_vpc.eden_vpc.id
  cidr_block = var.cidrs["private1"]
  map_public_ip_on_launch = false
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "eden_private1"
  }
}

resource "aws_subnet" "eden_private2_subnet" {
  vpc_id = aws_vpc.eden_vpc.id
  cidr_block = var.cidrs["private2"]
  map_public_ip_on_launch = false
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "eden_private2"
  }
}

resource "aws_subnet" "eden_rds1_subnet" {
  vpc_id = aws_vpc.eden_vpc.id
  cidr_block = var.cidrs["rds1"]
  map_public_ip_on_launch = false
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "eden_rds1"
  }
}

resource "aws_subnet" "eden_rds2_subnet" {
  vpc_id = aws_vpc.eden_vpc.id
  cidr_block = var.cidrs["rds2"]
  map_public_ip_on_launch = false
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "eden_rds2"
  }
}

resource "aws_subnet" "eden_rds3_subnet" {
  vpc_id = aws_vpc.eden_vpc.id
  cidr_block = var.cidrs["rds3"]
  map_public_ip_on_launch = false
  availability_zone = data.aws_availability_zones.available.names[2]

  tags = {
    Name = "eden_rds3"
  }
}
