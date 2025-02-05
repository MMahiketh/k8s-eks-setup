output "sg" {
  value = data.aws_security_group.allowmyip.id
}

output "ami_id" {
  value = data.aws_ami.amazonlinux.id
}