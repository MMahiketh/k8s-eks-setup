resource "aws_instance" "workstation" {
  ami           = local.ami_id
  instance_type = var.instance_type
  key_name      = "linux-key devops shiva"
  user_data     = file("setup.sh")

  user_data_replace_on_change = false
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
      "sleep 30",
      # "mkdir -p /home/ec2-user/.aws/",
      # "echo '[default]' > /home/ec2-user/.aws/config",
      # "echo 'region = us-east-1' >> /home/ec2-user/.aws/config",
      # "git clone https://github.com/MMahiketh/k8s-eks-setup.git",
      "eksctl create cluster --config-file=k8s-eks-setup/eks.yaml --dry-run"
    ]
  }
}
