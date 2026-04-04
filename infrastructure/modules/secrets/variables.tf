variable "db_user" {
  description = "Database username"
  type        = string
}

variable "db_pass" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_endpoint" {
  description = "RDS endpoint"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name for videos"
  type        = string
}

variable "huggingface_api_key" {
  description = "HuggingFace API key"
  type        = string
  sensitive   = true
}