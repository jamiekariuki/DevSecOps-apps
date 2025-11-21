//kms encryption for eks secrets in etcd
resource "aws_kms_key" "k8s_encryption" {
  description             = "KMS key for encrypting EKS secrets"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

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

encryption_config = {
  provider_key_arn = aws_kms_key.k8s_encryption.arn
  resources        = ["secrets"]
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
      max_size     = 3
      desired_size = 1
    }
  }

  tags = {
    Environment = var.ENV_PREFIX
    Terraform   = "true"
  }
}

/* //helm resource for argocd  (installing argocd)
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.4.3"
  namespace        = "argocd"
  create_namespace = true

  depends_on = [module.eks]
} */


/* resource "kubernetes_namespace" "env" {
  metadata {
    name = var.ENV_PREFIX
  }

  depends_on = [ module.eks ]
} */


//service account for eso 
/* resource "kubernetes_service_account" "eso_sa" {
  metadata {
    name = var.service_account_name
    namespace = var.ENV_PREFIX
    
    annotations = {
      "eks.amazonaws.com/role-arn" = module.external_secrets_irsa.arn
    }
  }

  depends_on = [module.eks, kubernetes_namespace.env]
} */

//helm isntall eso
/* resource "helm_release" "external_secrets" {
  name = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart = "external-secrets"
  namespace = "external-secrets"
  create_namespace = true

  depends_on = [ module.eks ]
} */

//secret store for eso
/* resource "kubernetes_manifest" "secretstore" {
  manifest = yamldecode(<<EOF
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: secretstore
  namespace: ${var.ENV_PREFIX}
spec:
  provider:
    aws:
      service: SecretsManager
      region: ${var.region}
      auth:
        jwt:
          serviceAccountRef:
            name: ${var.service_account_name}
            namespace: ${var.ENV_PREFIX}
EOF
)

depends_on = [module.eks, helm_release.external_secrets, kubernetes_service_account.eso_sa ]

} */

//external secret
/* resource "kubernetes_manifest" "external_secrets_manifest" {
  manifest = yamldecode(<<EOF
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: db-credentials
  namespace: ${var.ENV_PREFIX}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: secretstore
    kind: SecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
  - secretKey: POSTGRES_USER
    remoteRef:
      key: ${module.db.db_instance_master_user_secret_arn}
      property: username
  - secretKey: POSTGRES_PASSWORD
    remoteRef:
      key: ${module.db.db_instance_master_user_secret_arn}
      property: password
  - secretKey: POSTGRES_DB
    remoteRef:
      key: ${module.db.db_instance_master_user_secret_arn
      property: dbname
  - secretKey: POSTGRES_HOST
    remoteRef:
      key: ${module.db.db_instance_master_user_secret_arn}
      property: host
  - secretKey: POSTGRES_PORT
    remoteRef:
      key: ${module.db.db_instance_master_user_secret_arn}
      property: port
EOF
)

  depends_on = [module.eks, kubernetes_manifest.secretstore ]
} */
//test