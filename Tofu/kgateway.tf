

data "http" "gateway_api_manifest" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml"
}

locals {
  raw_docs = [
    for doc in split("---", data.http.gateway_api_manifest.response_body) :
    trimspace(doc)
    if trimspace(doc) != ""
  ]

  # valid_docs = [
  #   for doc in local.raw_docs :
  #   doc
  #   if length(doc) > 5 &&
  #   strcontains(doc, "apiVersion:") &&
  #   strcontains(doc, "kind:") &&
  #   !startswith(doc, "#")
  # ]

  gateway_api_manifests = toset([
    for idx, doc in local.raw_docs :
    doc
    if can(yamldecode(doc))
  ])
}

# resource "kubernetes_manifest" "gateway_api" {
#   for_each = local.gateway_api_manifests
#   manifest = each.value

#   depends_on = [ exoscale_sks_nodepool.kube-sg-nodepool ]
# }
 
# output "gateway_out" {
#    value = local.gateway_api_manifests["doc-1"]
#   #  description = "gateway"
# }


resource "kubectl_manifest" "gateway_api" {
  for_each = local.gateway_api_manifests
  yaml_body = each.key
  depends_on = [ exoscale_sks_nodepool.kube-sg-nodepool ]
  
}
 
resource "kubernetes_namespace" "kgateway_system" {
  metadata {
    name = "kgateway-system"
  }

  lifecycle {
    ignore_changes = [metadata[0].labels, metadata[0].annotations]
  }

  depends_on = [ exoscale_sks_nodepool.kube-sg-nodepool ]
}

resource "kubectl_manifest" "kgateway_crds_helm" {
   yaml_body =  yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "kgateway-crds-helm"
      namespace = "argocd"
    }

    spec = {
      destination = {
        namespace = "kgateway-system"
        server    = "https://kubernetes.default.svc"
      }

      project = "default"

      source = {
        chart          = "kgateway-crds"
        repoURL        = "cr.kgateway.dev/kgateway-dev/charts"
        targetRevision = "v2.0.3"

        helm = {
          skipCrds = false
        }
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }

        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  })

  depends_on = [exoscale_sks_nodepool.kube-sg-nodepool, kubernetes_namespace.argocd_namespace, helm_release.argocd]
}

resource "kubectl_manifest" "kgateway_helm" {
  yaml_body  = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "kgateway-helm"
      namespace = "argocd"
    }

    spec = {
      destination = {
        namespace = "kgateway-system"
        server    = "https://kubernetes.default.svc"
      }

      project = "default"

      source = {
        chart          = "kgateway"
        repoURL        = "cr.kgateway.dev/kgateway-dev/charts"
        targetRevision = "v2.0.3"

        helm = {
          skipCrds = false
        }
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }

        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  })

  depends_on = [kubernetes_namespace.kgateway_system, kubernetes_namespace.argocd_namespace, helm_release.argocd]
}
