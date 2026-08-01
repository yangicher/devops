terraform {
  backend "s3" {
    bucket         = "yangicher-devops-tf-state-2026"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}