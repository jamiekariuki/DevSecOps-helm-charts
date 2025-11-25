resource "kubernetes_manifest" "argo_root" {
  manifest = yamldecode(file("${path.module}/apps/root.yaml"))
}


