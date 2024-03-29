provider "aws" {
  region     = var.aws_region
  profile    = var.aws_profile
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}



#--- Direct Connect ---
resource "aws_dx_gateway" "eden_aws_dxgw" {
  name            = "eden-aws-dx"
  amazon_side_asn = var.dxgw_asn
}

resource "aws_dx_connection" "eden_aws_dx" {
  name      = "eden-dx-connection"
  bandwidth = "1Gbps"
  location  = var.dx_location
}



#--- VPC ---
resource "aws_vpn_gateway" "eden_vpn_gw" {
  vpc_id          = aws_vpc.eden_vpc.id
  amazon_side_asn = var.dxgw_asn
  tags = {
    Name = "eden_vpn_gw"
  }
}

resource "aws_vpc" "eden_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
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
    gateway_id = aws_internet_gateway.eden_internet_gateway.id
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
  vpc_id                  = aws_vpc.eden_vpc.id
  cidr_block              = var.cidrs["public1"]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "eden_public1"
  }
}
resource "aws_subnet" "eden_public2_subnet" {
  vpc_id                  = aws_vpc.eden_vpc.id
  cidr_block              = var.cidrs["public2"]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "eden_public2"
  }
}


resource "aws_subnet" "eden_private1_subnet" {
  vpc_id                  = aws_vpc.eden_vpc.id
  cidr_block              = var.cidrs["private1"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "eden_private1"
  }
}

resource "aws_subnet" "eden_private2_subnet" {
  vpc_id                  = aws_vpc.eden_vpc.id
  cidr_block              = var.cidrs["private2"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "eden_private2"
  }
}

resource "aws_subnet" "eden_rds1_subnet" {
  vpc_id                  = aws_vpc.eden_vpc.id
  cidr_block              = var.cidrs["rds1"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "eden_rds1"
  }
}

resource "aws_subnet" "eden_rds2_subnet" {
  vpc_id                  = aws_vpc.eden_vpc.id
  cidr_block              = var.cidrs["rds2"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "eden_rds2"
  }
}


#Rds Subnet group
resource "aws_db_subnet_group" "eden_rds_subnetgroup" {
  name = "eden_rds_subnetgroup"

  subnet_ids = [aws_subnet.eden_rds1_subnet.id,
  aws_subnet.eden_rds2_subnet.id]

  tags = {
    name = "eden_rds_subgrp"
  }
}

#Subnet associations
resource "aws_route_table_association" "eden_public1_assoc" {
  subnet_id      = aws_subnet.eden_public1_subnet.id
  route_table_id = aws_route_table.eden_public_rt.id
}

resource "aws_route_table_association" "eden_public2_assoc" {
  subnet_id      = aws_subnet.eden_public2_subnet.id
  route_table_id = aws_route_table.eden_public_rt.id
}

resource "aws_route_table_association" "eden_private1_assoc" {
  subnet_id      = aws_subnet.eden_private1_subnet.id
  route_table_id = aws_default_route_table.eden_private_rt.id
}

resource "aws_route_table_association" "eden_private2_assoc" {
  subnet_id      = aws_subnet.eden_private2_subnet.id
  route_table_id = aws_default_route_table.eden_private_rt.id
}





#--- Security Groups

#Public
resource "aws_security_group" "eden_web_sg" {
  name        = "eden_web_sg"
  description = "Used by ELB for public access to web servers"
  vpc_id      = aws_vpc.eden_vpc.id

  #http from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # For the sake of this exercise, allow all traffic out
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Private
resource "aws_security_group" "eden_app_sg" {
  name        = "eden_app_sg"
  description = "Used for frontend to backend comms"
  vpc_id      = aws_vpc.eden_vpc.id

  #HTTP
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#RDS Security Group
resource "aws_security_group" "eden_rds_sg" {
  name        = "eden_rds_sg"
  description = "Used for RDS instances"
  vpc_id      = aws_vpc.eden_vpc.id

  #SQL access from public and private SGs
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eden_web_sg.id, aws_security_group.eden_app_sg.id]
  }
}


#--- ELB ---

resource "aws_elb" "eden_web_elb" {
  name = "eden-web-elb"

  subnets = [aws_subnet.eden_public1_subnet.id,
  aws_subnet.eden_public2_subnet.id]

  security_groups = [aws_security_group.eden_web_sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = var.elb_healthy_threshold
    unhealthy_threshold = var.elb_unhealthy_threshold
    timeout             = var.elb_timeout
    target              = "HTTP:80/index.html"
    interval            = var.elb_interval
  }

  cross_zone_load_balancing   = true
  idle_timeout                = var.elb_timeout
  connection_draining         = true
  connection_draining_timeout = var.elb_drain_timeout

  tags = {
    name = "eden_web_elb"
  }
}

resource "aws_elb" "eden_app_elb" {
  name = "eden-app-elb"

  subnets = [aws_subnet.eden_private1_subnet.id,
  aws_subnet.eden_private2_subnet.id]

  security_groups = [aws_security_group.eden_app_sg.id]

  internal = true

  listener {
    instance_port     = 8002
    instance_protocol = "TCP"
    lb_port           = 8111
    lb_protocol       = "TCP"
  }

  health_check {
    healthy_threshold   = var.elb_healthy_threshold
    unhealthy_threshold = var.elb_unhealthy_threshold
    timeout             = var.elb_timeout
    target              = "TCP:8002"
    interval            = var.elb_interval
  }

  cross_zone_load_balancing   = true
  idle_timeout                = var.elb_idle_timeout
  connection_draining         = true
  connection_draining_timeout = var.elb_drain_timeout

  tags = {
    name = "eden_app_elb"
  }
}




#---RDS Instances---

resource "aws_db_instance" "eden_primary_db" {
  allocated_storage       = 10
  engine                  = "postgres"
  engine_version          = "11.5"
  instance_class          = var.db_instance_class
  name                    = var.db_name
  username                = var.db_user
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.eden_rds_subnetgroup.name
  vpc_security_group_ids  = [aws_security_group.eden_rds_sg.id]
  skip_final_snapshot     = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  apply_immediately       = false
  backup_retention_period = var.db_bak_retention
  deletion_protection     = true
  publicly_accessible     = false

}



resource "aws_db_instance" "eden_replica_db" {

  instance_class         = var.db_instance_class
  vpc_security_group_ids = [aws_security_group.eden_rds_sg.id]
  availability_zone      = data.aws_availability_zones.available.names[1]

  replicate_source_db = aws_db_instance.eden_primary_db.id
}


#---ASG Configs---

# Web frontend

# Using standard AWS AMI for tnis exercise
resource "aws_launch_configuration" "eden_web_lc" {
  name_prefix     = "eden_web_lc-"
  image_id        = var.web_ami
  instance_type   = var.web_lc_instance_type
  security_groups = [aws_security_group.eden_web_sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eden_web_asg" {
  name                      = aws_launch_configuration.eden_web_lc.id
  max_size                  = var.asg_web_max
  min_size                  = var.asg_web_min
  health_check_grace_period = var.asg_web_grace
  health_check_type         = var.asg_web_hct
  desired_capacity          = var.asg_web_cap
  force_delete              = true
  load_balancers            = [aws_elb.eden_web_elb.id]

  vpc_zone_identifier = [aws_subnet.eden_public1_subnet.id,
  aws_subnet.eden_public2_subnet.id]

  availability_zones = [data.aws_availability_zones.available.names[0],
  data.aws_availability_zones.available.names[1]]

  launch_configuration = aws_launch_configuration.eden_web_lc.name

  tag {
    key                 = "Name"
    value               = "eden_web-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


# App servers

# Using standard AWS AMI for tnis exercise
resource "aws_launch_configuration" "eden_app_lc" {
  name_prefix     = "eden_app_lc-"
  image_id        = var.app_ami
  instance_type   = var.app_lc_instance_type
  security_groups = [aws_security_group.eden_app_sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eden_app_asg" {
  name                      = aws_launch_configuration.eden_app_lc.id
  max_size                  = var.asg_app_max
  min_size                  = var.asg_app_min
  health_check_grace_period = var.asg_app_grace
  health_check_type         = var.asg_app_hct
  desired_capacity          = var.asg_app_cap
  force_delete              = true
  load_balancers            = [aws_elb.eden_app_elb.id]

  vpc_zone_identifier = [aws_subnet.eden_private1_subnet.id,
  aws_subnet.eden_private2_subnet.id]

  availability_zones = [data.aws_availability_zones.available.names[0],
  data.aws_availability_zones.available.names[1]]

  launch_configuration = aws_launch_configuration.eden_app_lc.name

  tag {
    key                 = "Name"
    value               = "eden_app-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}