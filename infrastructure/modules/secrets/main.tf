resource "aws_secretsmanager_secret" "app" {
  name = "transcriber-secrets"
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id

  secret_string = jsonencode({
    DATABASE_URL = "postgresql://${var.db_user}:${var.db_pass}@${var.db_endpoint}/transcriber_db"
    HUGGINGFACE_API_KEY = var.huggingface_api_key
    S3_VIDEO_BUCKET_NAME = var.bucket_name
  })
}