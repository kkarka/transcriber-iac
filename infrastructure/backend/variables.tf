variable "region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "ap-south-1"
}

variable "bucket_prefix" {
  description = "Prefix for Terraform state bucket"
  type        = string
  default     = "arka-terraform-state"
}