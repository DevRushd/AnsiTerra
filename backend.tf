terraform {
  backend "s3" {
    bucket         = "ansiterra-tfstate"
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "ansiterra-tfstate-lock"
  }
}
