apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-stage
  namespace: argocd
spec:
  project: default
  source:
    repoURL: "${repo_url}"
    targetRevision: "${target_revision}"
    path: kustomize/overlays/stage
  destination:
    server: https://kubernetes.default.svc
    namespace: stage
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
