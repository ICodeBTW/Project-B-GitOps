
resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    name = "argocd"
    labels = {
      "name" = "argocd"
    }
  }
  depends_on = [exoscale_sks_nodepool.kube-sg-nodepool]
}

# Local testing
# resource "local_sensitive_file" "kubeconfig_file" {

#   filename = "./kubeconfig.yml"
#   content = exoscale_sks_kubeconfig.kube-sg-kubeconfig.kubeconfig

#   provisioner "local-exec" {
#     when = destroy
#     command = "rm -rf ./kubeconfig.yml"
#   }

# }

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.6"
  namespace  = kubernetes_namespace.argocd_namespace.metadata[0].name

  values = [
    yamlencode({
      global = {
        domain = "argocd.example.com"
      }

      server = {
        # Todo: move away from loadbalancers ( Expensive ) switch to ingress -> nginx
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/exoscale-loadbalancer-name" = "kube-sg-cluster-argocd-lb"
          }
        }

        ingress = {
          enabled = false
        }

        config = {
          "application.instanceLabelKey"   = "argocd.argoproj.io/instance"
          "server.rbac.log.enforce.enable" = "true"
          "exec.enabled"                   = "true"
        }

        rbacConfig = {
          "policy.default" = "role:readonly"
          "policy.csv"     = <<EOF
p, role:admin, applications, *, */*, allow
p, role:admin, clusters, *, *, allow
p, role:admin, repositories, *, *, allow
g, kubernetes-admins, role:admin
EOF
        }
      }

      controller = {
        metrics = {
          enabled = true
        }
      }

      repoServer = {
        metrics = {
          enabled = true
        }
      }

      redis = {
        metrics = {
          enabled = true
        }
      }

      applicationSet = {
        enabled = true
      }

      notifications = {
        enabled = true
      }
    })
  ]

  depends_on = [kubernetes_namespace.argocd_namespace]
}



resource "kubernetes_manifest" "argocd_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "app"
      namespace = kubernetes_namespace.argocd_namespace.metadata[0].name
    }

    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/ICodeBTW/Project-B-GitOps.git"
        targetRevision = "HEAD"
        path           = "Kubernetes/app/"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
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
  }

  depends_on = [
    helm_release.argocd,
    kubernetes_namespace.argocd_namespace
  ]
}


data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd_namespace.metadata[0].name
  }
  depends_on = [helm_release.argocd]
}

output "argocd_server_url" {
  description = "ArgoCD server URL"
  value       = length(data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress) > 0 && data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].ip != "" ? "https://${data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].ip}" : "LoadBalancer IP not yet assigned"
}
