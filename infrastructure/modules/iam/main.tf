data "aws_iam_policy_document" "irsa_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:transcriber:app-sa"]
    }
  }
}

resource "aws_iam_role" "irsa" {
  name               = "${var.project_name}-irsa"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role.json
}

resource "aws_iam_policy" "s3" {
  name = "${var.project_name}-s3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = [
        var.bucket_arn,
        "${var.bucket_arn}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.irsa.name
  policy_arn = aws_iam_policy.s3.arn
}

resource "aws_iam_policy" "secrets" {
  name = "${var.project_name}-secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_attach" {
  role       = aws_iam_role.irsa.name
  policy_arn = aws_iam_policy.secrets.arn
}