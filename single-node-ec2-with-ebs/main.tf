terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  shared_config_files      = [var.aws_config_file]
  shared_credentials_files = [var.aws_credentials_file]
  profile                  = var.aws_profile
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "my_gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.name_prefix}-gw"
  }
}

resource "aws_route_table" "my_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gw.id
  }

  tags = {
    Name = "${var.name_prefix}-rt"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "${var.name_prefix}-subnet"
  }
}

resource "aws_route_table_association" "my_rta" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_rt.id
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_all"
  }
}

resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  associate_public_ip_address = true
  subnet_id = aws_subnet.my_subnet.id

  key_name = var.key_name

  tags = {
    Name = "${var.name_prefix}-instance"
  }

  vpc_security_group_ids = [aws_security_group.allow_all.id]

  root_block_device {
    delete_on_termination = true
    volume_size = var.root_device_size
    volume_type = "gp2"

    tags = {
        Name = "${var.name_prefix}-root"
    }
  }

  ebs_block_device {
    delete_on_termination = true
    volume_size = var.ebs_device_size
    volume_type = "gp3"

    device_name = "/dev/xvdz"

    tags = {
        Name = "${var.name_prefix}-rook"
    }
  }
}

output "ssh_info" {
  value = [
    "ssh ubuntu@${aws_instance.my_instance.public_ip} -i ${var.instance_keypair_file}",
  ]
}