resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  timeout = 900

  values = [
    templatefile("${path.module}/values.yaml", {
      service_type = var.service_type
    })
  ]
}

resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts"
  namespace = kubernetes_namespace.argocd.metadata[0].name

  values = [
    yamlencode({
      argocdNamespace = kubernetes_namespace.argocd.metadata[0].name

      repositories = [
        {
          name = "django-app-repo"
          type = "git"
          url  = var.repo_url
        }
      ]

      applications = [
        {
          name                 = var.application_name
          repoURL              = var.repo_url
          targetRevision       = var.target_revision
          path                 = var.chart_path
          destinationNamespace = var.destination_namespace
          automated            = var.automated_sync
          prune                = var.prune
          selfHeal             = var.self_heal
        }
      ]
    })
  ]

  depends_on = [helm_release.argocd]
}

data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  depends_on = [helm_release.argocd]
}

data "kubernetes_secret" "argocd_admin" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  depends_on = [helm_release.argocd]
}
