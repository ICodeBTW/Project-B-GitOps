resource "helm_release" "cnpg" {
  name             = "cnpg"
  repository       = "https://cloudnative-pg.github.io/charts"
  chart            = "cloudnative-pg"
  namespace        = "cnpg-system"
  create_namespace = true

  timeout = 300
  wait    = true

  # Optional: Cleanup on fail
  cleanup_on_fail = true
}