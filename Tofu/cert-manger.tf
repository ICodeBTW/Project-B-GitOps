resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.18.2"
  
  set = [{
    name  = "crds.enabled"
    value = "true"
  },
  {
    name  = "prometheus.enabled"
    value = "true"
  },
  {
    name  = "webhook.timeoutSeconds"
    value = "4"
  },
  {
    name  = "config.enableGatewayAPI"
    value = "true"
  }]
  
  depends_on = [exoscale_sks_nodepool.kube-sg-nodepool]
}