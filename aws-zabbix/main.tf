provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "zabbix" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "zabbix" {
  vpc_id = "${aws_vpc.zabbix.id}"
}

resource "aws_subnet" "public" {
  availability_zone       = "${var.availability_zone}"
  map_public_ip_on_launch = true
  vpc_id                  = "${aws_vpc.zabbix.id}"
  cidr_block              = "${var.vpc_cidr}"

  tags {
    Name = "Public Subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.zabbix.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.zabbix.id}"
  }

  tags {
    Name = "Public Subnet"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "zabbix" {
  name   = "zabbix"
  vpc_id = "${aws_vpc.zabbix.id}"

  ingress {
    from_port   = 22                   #to ssh
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.allowed_ips}"
  }

  ingress {
    from_port   = 80            #to app
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443           #to app
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0             #to internet
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu18_lastest" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

resource "aws_instance" "zabbix" {
  ami                    = "${data.aws_ami.ubuntu18_lastest.id}"
  instance_type          = "${var.instance_type}"
  vpc_security_group_ids = ["${aws_security_group.zabbix.id}"]
  user_data              = "${var.userdata}"
  key_name               = "${var.ssh_key}"
  subnet_id              = "${aws_subnet.public.id}"

  tags {
    Name = "zabbix"
  }
}
