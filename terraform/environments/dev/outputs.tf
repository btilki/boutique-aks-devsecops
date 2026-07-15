output "resource_group_name" {
  description = "Platform resource group name."
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "Platform resource group ARM ID."
  value       = module.resource_group.id
}

output "location" {
  description = "Azure region."
  value       = module.resource_group.location
}

output "vnet_id" {
  description = "Virtual network ARM ID."
  value       = module.networking.vnet_id
}

output "aks_subnet_id" {
  description = "AKS subnet ID for Topic 03 cluster module."
  value       = module.networking.aks_subnet_id
}

output "dns_zone_name" {
  description = "Azure DNS zone name."
  value       = module.dns.zone_name
}

output "dns_name_servers" {
  description = "Delegate these NS records at your domain registrar."
  value       = module.dns.name_servers
}

# Topic 03 outputs

output "acr_name" {
  description = "ACR registry name."
  value       = module.acr.name
}

output "acr_login_server" {
  description = "ACR login server FQDN."
  value       = module.acr.login_server
}

output "key_vault_name" {
  description = "Key Vault name."
  value       = module.key_vault.name
}

output "key_vault_uri" {
  description = "Key Vault URI."
  value       = module.key_vault.vault_uri
}

output "aks_cluster_name" {
  description = "AKS cluster name."
  value       = module.aks.name
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity and ADO federation (Topic 04)."
  value       = module.aks.oidc_issuer_url
}

output "aks_node_resource_group" {
  description = "AKS node resource group (MC_*)."
  value       = module.aks.node_resource_group
}

output "platform_identity_client_id" {
  description = "Platform UAMI client ID for Workload Identity."
  value       = module.identities.platform_identity_client_id
}

# Topic 04 outputs

output "ado_pipeline_identity_client_id" {
  description = "ADO pipeline UAMI client ID for ARM service connection."
  value       = module.ado_federation.identity_client_id
}

output "ado_oidc_issuer" {
  description = "OIDC issuer for ADO federated credential."
  value       = module.ado_federation.issuer
}

output "ado_oidc_subject" {
  description = "Federation subject for ADO service connection validation."
  value       = module.ado_federation.subject
}

output "ado_service_connection_name" {
  description = "Expected ADO ARM service connection name."
  value       = module.ado_federation.service_connection_name
}

output "azure_tenant_id" {
  description = "Entra tenant ID."
  value       = module.ado_federation.tenant_id
}

output "azure_subscription_id" {
  description = "Azure subscription ID."
  value       = module.ado_federation.subscription_id
}
