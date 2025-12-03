apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ems
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${repo_url}
    targetRevision: HEAD
    path: ${repo_path}
    directory:
      recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: ${namespace}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
