terraform {
  backend "s3" {
    bucket         = "arka-terraform-state-6a2271c3"
    key            = "transcriber/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}