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

  # setup aws configuration
  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("../../linux-key")
  }

  provisioner "file" {
    source      = "~/.aws/credentials"
    destination = "/home/ec2-user/.aws/credentials"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 40",
      # "mkdir -p /home/ec2-user/.aws/",
      # "echo '[default]' > /home/ec2-user/.aws/config",
      # "echo 'region = us-east-1' >> /home/ec2-user/.aws/config",
      # "git clone https://github.com/MMahiketh/k8s-eks-setup.git",
      "eksctl create cluster --config-file=k8s-eks-setup/eks.yaml",
      "git clone https://github.com/MMahiketh/k8s-expense.git"
    ]
  }

  provisioner "remote-exec" {
    when   = destroy
    inline = [
      "eksctl delete cluster --config-file=k8s-eks-setup/eks.yaml"
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