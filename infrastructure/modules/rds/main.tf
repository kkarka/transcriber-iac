resource "aws_db_subnet_group" "db" {
  name       = "${var.project_name}-db"
  subnet_ids = var.private_subnets
}

resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-db"

  engine         = "postgres"
  instance_class = "db.t3.micro"

  allocated_storage = 20

  db_name  = "transcription_db"
  username = var.db_user
  password = var.db_pass

  vpc_security_group_ids = [var.db_sg]
  db_subnet_group_name   = aws_db_subnet_group.db.name

  skip_final_snapshot = true
}

resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"

  namespace = "transcriber"

  set {
    name  = "auth.enabled"
    value = "false"
  }
}