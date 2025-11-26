apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-${env_prefix}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: "${repo_url}"
    targetRevision: "${target_revision}"
    path: kustomize/overlays/${env_prefix}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${env_prefix}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

