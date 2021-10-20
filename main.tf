terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  # region  = "eu-central-1"
  region = "eu-north-1"
}

############### Public

resource "aws_vpc" "my_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "My-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "Internet Gateway"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "public_route"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "assoc_pub_sub" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_route.id
}


resource "aws_security_group" "public" {
  name        = "public"
  description = "ec2 public policy"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "icmp"
    from_port   = "-1"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public"
  }
}

data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = [
    "amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ami.id
  instance_type          = "t3.micro"
  key_name               = "mac-key"
  vpc_security_group_ids = [aws_security_group.public.id]
  subnet_id              = aws_subnet.public.id

  tags = {
    Name = "PublicEc2"
  }
}

######################## Privat


resource "aws_eip" "eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.privat.id

  tags = {
    Name = "NAT GW"
  }
}

resource "aws_subnet" "privat" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_route_table" "privat_route" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "privat_route"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "assoc_pri_sub" {
  subnet_id      = aws_subnet.privat.id
  route_table_id = aws_route_table.privat_route.id
}


resource "aws_security_group" "privat" {
  name        = "privat"
  description = "ec2 public policy"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "privat"
  }
}

resource "aws_instance" "privat_ec2" {
  ami                    = data.aws_ami.ami.id
  instance_type          = "t3.micro"
  key_name               = "mac-key"
  vpc_security_group_ids = [aws_security_group.privat.id]
  subnet_id              = aws_subnet.privat.id

  tags = {
    Name = "PrivatEc2"
  }
}
