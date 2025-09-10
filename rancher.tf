resource "kubernetes_namespace" "cattle_system" {
  metadata {
    name = "cattle-system"
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.15.0"

  create_namespace = true

  set = [
    { name = "installCRDs", value = "true" }
  ]
}


resource "helm_release" "rancher" {
  name       = "rancher"
  namespace  = kubernetes_namespace.cattle_system.metadata[0].name
  repository = "https://releases.rancher.com/server-charts/stable"
  chart      = "rancher"
  version    = "2.12.1"

  depends_on = [helm_release.cert_manager]

  set = [
    {
      name  = "hostname"
      value = "rancher.herrhornberger.de"
    },
    {
      name  = "replicas"
      value = "1"
    },
    {
      name  = "ingress.tls.source"
      value = "letsEncrypt"
    },
    {
      name  = "letsEncrypt.email"
      value = "your@email.com"
    },
    {
      name  = "service.type"
      value = "LoadBalancer"
    }
  ]
}
