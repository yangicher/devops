resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/part-of" = "monitoring"
    }
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  timeout = 900

  values = [
    templatefile("${path.module}/values.yaml", {
      prometheus_retention      = var.prometheus_retention
      prometheus_storage_size   = var.prometheus_storage_size
      prometheus_cpu_request    = var.resources.prometheus.requests.cpu
      prometheus_memory_request = var.resources.prometheus.requests.memory
      prometheus_cpu_limit      = var.resources.prometheus.limits.cpu
      prometheus_memory_limit   = var.resources.prometheus.limits.memory

      grafana_admin_password = var.grafana_admin_password
      grafana_service_type   = var.grafana_service_type
      grafana_storage_size   = var.grafana_storage_size
      grafana_cpu_request    = var.resources.grafana.requests.cpu
      grafana_memory_request = var.resources.grafana.requests.memory
      grafana_cpu_limit      = var.resources.grafana.limits.cpu
      grafana_memory_limit   = var.resources.grafana.limits.memory

      storage_class = var.storage_class
    })
  ]
}

resource "kubernetes_manifest" "app_service_monitor" {
  count = var.enable_app_service_monitor ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "${var.app_label}-monitor"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        release = "kube-prometheus-stack"
      }
    }

    spec = {
      namespaceSelector = {
        matchNames = [var.app_namespace]
      }
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = var.app_label
        }
      }
      endpoints = [
        {
          port     = "http"
          path     = "/metrics"
          interval = "30s"
        }
      ]
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

data "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
