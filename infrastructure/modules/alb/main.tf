############################################
# IAM POLICY
############################################

resource "aws_iam_policy" "alb" {
  name   = "${var.cluster_name}-alb-controller"
  policy = file("${path.module}/alb-policy.json")
}

############################################
# IAM ROLE (IRSA)
############################################

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "alb" {
  name               = "${var.cluster_name}-alb-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb.name
  policy_arn = aws_iam_policy.alb.arn
}

############################################
# HELM RELEASE
############################################

# resource "helm_release" "alb_controller" {
#   name       = "aws-load-balancer-controller"
#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-load-balancer-controller"

#   namespace = "kube-system"

#   set {
#     name  = "clusterName"
#     value = var.cluster_name
#   }

#   set {
#     name  = "region"
#     value = var.region
#   }

#   set {
#     name  = "vpcId"
#     value = var.vpc_id
#   }

#   set {
#     name  = "serviceAccount.create"
#     value = "true"
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = "aws-load-balancer-controller"
#   }

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = aws_iam_role.alb.arn
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.alb_attach
#   ]
# }
