variable "ami" {
  default = "ami-08ae04824d9fd0094"
}
variable "server-name" {
}

variable "instance_count" {
  default = "2"
}
variable "subnet_id" {
  type = list
}

variable "instance_type" {
  default = "t2.nano"
}

variable "aws_region" {
  default = "ap-south-1"
}
variable "security_group_ids" {
  type        = list
  description = "The security groups to be associated to aws instances"
}
