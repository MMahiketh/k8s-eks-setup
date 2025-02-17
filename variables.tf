variable "instance_type" {
  default = "t3.micro"
  type    = string
}

variable "sg_name" {
  type    = string
  default = "AllowAllMyIP"
}

variable "aws_access_key" {
  type = string
  #  sensitive = true
}

variable "aws_secret_key" {
  type = string
  #  sensitive = true
}

variable "create_cluster__Y_or_n" {
  type = string
}
