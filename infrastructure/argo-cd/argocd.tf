//helm resource for argocd  (installing argocd)
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.4.3"
  namespace        = "argocd"
  create_namespace = true


}

resource "time_sleep" "wait_for_crds" {
  depends_on = [helm_release.argocd]
  create_duration = "20s"
}

resource "kubernetes_manifest" "argo_root" {
  depends_on = [time_sleep.wait_for_crds]
  manifest = yamldecode(file("${path.module}/apps/root.yaml"))
}
