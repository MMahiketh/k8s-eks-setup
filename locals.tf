locals {
  ami_id = data.aws_ami.amazonlinux.id
  sg     = data.aws_security_group.allowmyip.id
}