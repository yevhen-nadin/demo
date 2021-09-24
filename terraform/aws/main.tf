provider "aws" {
  region = "eu-central-1" # "us-east-2"
  # version = "v2.70.0"
}
  
resource "aws_instance" "test_VM" {
  # Amazon Linux AMI 2017.03.1 (HVM)
  ami           = "ami-07df274a488ca9195" # us-esat-2 "ami-00dfe2c7ce89a450b"
  instance_type = "t2.micro"
  
  associate_public_ip_address = true
  
  user_data = "${file("userdata.sh")}"

  tags = {
    Name = var.vm_name
  }
}

variable "vm_name" {
  default = "demo1"
  description = "Name for VM to be created"
}
