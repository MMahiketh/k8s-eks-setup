variable "instance_type" {
  default = "t3.micro"
  type    = string
}

variable "sg_name" {
  type    = string
  default = "AllowAllMyIP"
}