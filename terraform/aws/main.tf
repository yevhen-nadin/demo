provider "aws" {
  region = "eu-central-1"
}
  
resource "random_id" "sec" {
  byte_length = 8
}


variable "vm_name" {
  description = "Name for VM to be created"
  default = "Demo WEB page"
}

resource "aws_security_group" "allow_http" {
  name        = "allow_all_http_demo_${random_id.sec.hex}"
  description = "Allow HTTP inbound traffic for Demo purpose"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  
   tags = {
    Name = "allow_all"
	env = "Demo AWS via Terraform"
  }

}

resource "aws_instance" "test_VM" {
	ami = "ami-0b418580298265d5c"
	instance_type = "t2.micro"
	#key_name = "deployer-key"
	
	security_groups = ["${aws_security_group.allow_http.name}"]

    user_data = "${file("userdata.sh")}"

    tags {
        Name = "${var.vm_name}"	
		env = "Demo AWS via Terraform"
	}
}
