resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  namespace = kubernetes_namespace.argocd.metadata[0].name

  values = [<<EOF
server:
  service:
    type: ClusterIP
  extraArgs:
    - --insecure
EOF
  ]
}

resource "kubernetes_manifest" "transcriber_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "transcriber"
      namespace = "argocd"
    }

    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/kkarka/transcriber-iac"
        targetRevision = "main"
        path           = "app/helm/transcriber"

        helm = {
          valueFiles = ["values-dev.yaml"]

          parameters = [
            {
              name  = "env.DATABASE_URL"
              value = "postgresql://${var.db_user}:${var.db_pass}@${var.db_endpoint}/transcription_db"
            },
            {
              name  = "env.S3_VIDEO_BUCKET_NAME"
              value = var.bucket_name
            },
            {
              name  = "irsaRoleArn"
              value = var.irsa_role_arn
            },
            {
              name  = "ingress.certificateArn"
              value = var.certificate_arn
            },
            {
              name  = "env.HUGGINGFACE_API_KEY"
              value = var.huggingface_api_key
            }
          ]
        }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "transcriber"
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }

        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  depends_on = [helm_release.argocd]
}