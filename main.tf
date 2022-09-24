/* Start with adding the local variables, which will be used throughout the script ami-id of the instance */

locals {
  ami_id = "ami-09e67e426f25ce0d7"
  vpc_id = "[vpc id]"
  ssh_user = "ubuntu"
  key_name = "bmkey"
  private_key_path = "/home/labsuser/bmkey.pem"
}

/* Declare the provider and other required information linked with it, access key, secret key and token as per AWS 
(Or any cloud provider you are using) */

provider "aws" {
  region     = "us-east-1"
  access_key = "[AWS access key]"
  secret_key = "[AWS secret key]"
  token = "[AWS token]"
}

/* Creating a security group with the name of bmaccess and setting ingress egress security rules, it will automatically use the vac id from variables declared in local. */

resource "aws_security_group" "bmaccess" {
  name   = "bmaccess"
  vpc_id = local.vpc_id
    
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Resource creation using local variables - ami, security group and key. 

resource "aws_instance" "web" {
  ami = local.ami_id
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  vpc_security_group_ids =[aws_security_group.bmaccess.id]
  key_name = local.key_name

  tags = {
    Name = "bm ec2"
  }


  /* Setting up connection as we want to use ssh for Ansible configurations to run. Again using local variables for host ip, user name, and security key */

  connection {
    type = "ssh"
    host = self.public_ip
    user = local.ssh_user
    private_key = file(local.private_key_path)
    timeout = "4m"
  }


# Just to confirm whether our remote access is working

  provisioner "remote-exec" {
    inline = [
      "hostname"
    ]
  }


/* copying the remote machine ip to our local machine into my hosts file using local-exec */

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > myhosts"
  }


/* Running Ansible-playbook command through our local machine, using the myhosts as inventory file, ubuntu as user and wbkey.pem as private key. All satisfied using local variables */

  provisioner "local-exec" {
    command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} bm-engine.yml"
  }

}


# Saving the output.

output "instance_ip" {
  value = aws_instance.web.public_ip
}

