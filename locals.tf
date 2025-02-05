locals {
  ami_id = data.aws_ami.amazonlinux.id
  sg     = data.aws_security_group.allowmyip.id
  zone_id =  "Z02855522FE67JKRUDSDP"
  zone_name = "mahdo.site"
}