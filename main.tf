terraform {
  backend "s3" {
    bucket  = "flashcardify-infra"
    key     = "terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}

provider "aws" {
  region = "${var.region}"
}
