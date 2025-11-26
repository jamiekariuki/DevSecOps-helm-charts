locals {
  namespaces = [
    "monitoring",
    "externalsecret"
  ]
}

#namespaces
resource "kubernetes_namespace" "namespaces" {
  for_each = toset(local.namespaces)

  metadata {
    name = each.key
  }
}

resource "kubernetes_namespace" "env" {
  metadata {
    name = var.ENV_PREFIX
  }
}
 
#app of apps
locals {
  argocd_manifests = fileset("${path.module}/apps", "*.yaml.tpl")
}

resource "kubernetes_manifest" "argocd_apps" {
  depends_on = [ kubernetes_namespace.env, kubernetes_namespace.namespaces ]

  for_each = { for f in local.argocd_manifests : trim(f, ".tpl") => f }

  manifest = yamldecode(templatefile("${path.module}/apps/${each.value}", {
    repo_url        = var.repo_url
    target_revision = var.target_revision
    env_prefix      = var.ENV_PREFIX
  }))
}


