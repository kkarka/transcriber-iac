resource "aws_s3_bucket" "app" {
  bucket = "${var.project_name}-${var.environment}-videos"

  tags = {
    Name = "Transcriber S3"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.app.id

  block_public_acls   = true
  block_public_policy = true
}

resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = aws_s3_bucket.app.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET", "POST"]
    allowed_origins = ["https://transcriber.arkadevops.in"]
    expose_headers  = []
  }
}