//helm resource for argocd  (installing argocd)
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.4.3"
  namespace        = "argocd"
  create_namespace = true
}


resource "kubernetes_manifest" "argo_root" {
  manifest = yamldecode(file("${path.module}/apps/root.yaml"))
  depends_on = [ helm_release.argocd ]
}