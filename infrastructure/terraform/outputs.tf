output "irsa_arn" {
  value = module.external_secrets_irsa.arn
}

output "SecretsManager_arn" {
  value = module.db.db_instance_master_user_secret_arn
}