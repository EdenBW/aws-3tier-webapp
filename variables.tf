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
