variable "cluster_name" {}
variable "db_endpoint" {}
variable "db_user" {}
variable "db_pass" {}
variable "bucket_name" {}
variable "irsa_role_arn" {}
variable "certificate_arn" {}
variable "openai_api_key" {
  sensitive = true
}