variable "region" {
  type = string
}
variable "cidr" {
  type        = string
  description = "CIDR for VPC"
}
variable "cidr_block_public" {
  type        = string
  description = "CIDR public subnet"
}
variable "cidr_block_privat" {
  type        = string
  description = "CIDR public subnet"
}
