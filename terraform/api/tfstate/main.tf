provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "s3_tfstate" {
  bucket = "terraform-tfstate-grupo12-fiap-2024"
  acl    = "private"
}

terraform {
  backend "s3" {
    bucket = "terraform-tfstate-grupo12-fiap-2024"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }
}
