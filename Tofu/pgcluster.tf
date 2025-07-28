resource "helm_release" "cnpg_operator" {
  name             = "cnpg"
  repository       = "https://cloudnative-pg.github.io/charts"
  chart            = "cloudnative-pg"
  namespace        = "cnpg-system"
  create_namespace = true

  # Wait for cluster to be ready
  depends_on = [exoscale_sks_nodepool.kube-sg-nodepool]
}

 