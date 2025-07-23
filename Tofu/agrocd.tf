
# Fix this 
# resource "exoscale_sks_kubeconfig" "config" {
#   cluster_id = exoscale_sks_cluster.kube-sg-cluster.id
#   zone       = "ch-gva-2"
#   user = exoscale_sks_cluster.kube-sg-cluster.name
#   groups = [  ]
# }
 

provider "kubernetes" {
  host                   = exoscale_sks_cluster.kube-sg-cluster.endpoint
  cluster_ca_certificate = exoscale_sks_cluster.kube-sg-cluster.control_plane_ca
#   token                  =  
}

provider "helm" {
  kubernetes = {
  host                   = exoscale_sks_cluster.kube-sg-cluster.endpoint
  cluster_ca_certificate = exoscale_sks_cluster.kube-sg-cluster.control_plane_ca
 
  }
}
 
resource "helm_release" "argocd" {
  depends_on       = [exoscale_sks_nodepool.kube-sg-nodepool]
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "4.5.2"
  namespace        = "argocd"
  create_namespace = true

  set = [
    {
      name  = "server.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/exoscale-loadbalancer-name"
      value = "argocd-nlb"
    }
  ]
}
 
data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
  depends_on = [helm_release.argocd]
}

output "argocd_url" {
  description = "Public LoadBalancer URL for ArgoCD"
  value       = "http://${data.kubernetes_service.argocd_server.status.0.load_balancer.0.ingress.0.hostname}"
}