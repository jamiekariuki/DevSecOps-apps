//eks
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = "1.33"

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }

  # Optional
  endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.xlarge"]

      min_size     = 1
      max_size     = 5
      desired_size = 1
    }
  }

  tags = {
    Environment = var.ENV_PREFIX
    Terraform   = "true"
  }
}

//helm resource for argocd  (installing argocd)
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.4.3"
  namespace        = "argocd"
  create_namespace = true

  depends_on = [module.eks]
}

//service account for backend pods
resource "kubernetes_service_account" "backend_sa" {
  metadata {
    name = "backend-service-account"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.external_secrets_irsa.iam_policy_arn
    }
  }
}