resource "aws_instance" "workstation" {
  ami           = local.ami_id
  instance_type = var.instance_type
  key_name      = "linux-key devops shiva"
  user_data     = file("setup.sh")

  user_data_replace_on_change = true
  vpc_security_group_ids      = [local.sg]

  tags = {
    Name      = "workstation"
    Terraform = "True"
  }

  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("../../linux-key")
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "eksctl delete cluster --config-file=eks.yaml"
    ]
  }
}

resource "null_resource" "config_eks" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    instance_id = aws_instance.workstation.id
  }

  connection {
    host        = aws_instance.workstation.public_ip
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("../../linux-key")
  }

  provisioner "file" {
    source      = "config.sh"
    destination = "/tmp/config.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 60", # wait for workstation to run setup.sh
      "chmod +x /tmp/config.sh",
      "sh /tmp/config.sh ${var.aws_access_key} ${var.aws_secret_key} ${var.create_cluster__Y_or_n}"
    ]
  }
}

resource "aws_route53_record" "workstation" {
  zone_id         = local.zone_id
  name            = "workstation.${local.zone_name}"
  type            = "A"
  ttl             = 300
  records         = [aws_instance.workstation.public_ip]
  allow_overwrite = true
}