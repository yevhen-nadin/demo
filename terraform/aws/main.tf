provider "aws" {
  region = var.vm_region
  # version = "v2.70.0"
}
  
resource "aws_instance" "test_VM" {
  # Amazon Linux AMI 2017.03.1 (HVM)
  ami           = var.vm_ami # us-east-2 "ami-00dfe2c7ce89a450b" eu-central-1 "ami-07df274a488ca9195"
  instance_type = "t2.micro"
  
  associate_public_ip_address = true
  
  user_data = "${file("userdata.sh")}"

  tags = var.tags
}

variable "tags" {
   type = map
   description = "Tags to be set on VM"
   default = {
      Name = "Demo VM"
      Environment = "QA"
   }
}

variable "vm_region" {
  default = "us-east-2"
  description = "Default region"
}

variable "vm_ami" {
   default = "ami-00dfe2c7ce89a450b"
}
