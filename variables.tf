variable "aws_region" {}

variable "aws_profile" {}

variable "aws_access_key" {}
variable "aws_secret_key" {}


variable "dxgw_asn" {}

variable dx_location {}

variable "vpc_cidr" {}


data "aws_availability_zones" "available" {}

variable "cidrs" {
  type = map(string)
}



variable "db_instance_class" {}
variable "db_name" {}
variable "db_user" {}
variable "db_password" {}


variable "elb_healthy_threshold" {}
variable "elb_unhealthy_threshold" {}
variable "elb_timeout" {}
variable "elb_interval" {}

variable "elb_drain_timeout" {}
variable "elb_idle_timeout" {}
