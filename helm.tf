resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.10.1"

  create_namespace = true

  set = [
    {
      name  = "controller.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "controller.ingressClassResource.name"
      value = "nginx"
    },
    {
      name  = "controller.ingressClassResource.default"
      value = "true"
    }
  ]
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.16.1"

  create_namespace = true

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "extraArgs[0]"
      value = "--cluster-resource-namespace=cert-manager"
    },
    {
      name  = "extraArgs[1]"
      value = "--issuer-ambient-credentials"
    }
  ]
}

resource "helm_release" "rancher" {
  name       = "rancher"
  namespace  = "cattle-system"
  repository = "https://releases.rancher.com/server-charts/stable"
  chart      = "rancher"
  version    = "2.12.1"

  create_namespace = true

  depends_on = [
    helm_release.nginx_ingress,
    helm_release.cert_manager
  ]

  set = [
    {
      name  = "hostname"
      value = "rancher.herrhornberger.de"
    },
    {
      name  = "ingress.ingressClassName"
      value = "nginx"
    },
    {
      name  = "tls"
      value = "ingress"
    },
    {
      name  = "letsEncrypt.email"
      value = "christopher.hornberger@gmail.com"
    },
    {
      name  = "letsEncrypt.ingress.class"
      value = "nginx"
    },
    {
      name  = "letsEncrypt.environment"
      value = "production"
    },
    {
      name  = "ingress.tls.source"
      value = "letsEncrypt"
    }
  ]
}

resource "kubernetes_manifest" "letsencrypt_clusterissuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "christopher.hornberger@gmail.com"
        privateKeySecretRef = {
          name = "letsencrypt-prod-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}
