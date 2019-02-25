provider "aws" {
  region = "${var.region}"
}

resource "aws_instance" "web" {
  ami           = "ami-0fad7378adf284ce0"
  instance_type = "t2.micro"
}



