# Outputs consumed when configuring terraform/environments/dev/backend.tf

output "state_resource_group_name" {
  description = "Resource group containing the remote state storage account."
  value       = azurerm_resource_group.state.name
}

output "storage_account_name" {
  description = "Storage account name for the azurerm remote backend."
  value       = azurerm_storage_account.state.name
}

output "container_name" {
  description = "Blob container name for Terraform state files."
  value       = azurerm_storage_container.state.name
}

output "backend_config" {
  description = "Suggested backend block values for environments/dev (key is per-environment)."
  value = {
    resource_group_name  = azurerm_resource_group.state.name
    storage_account_name = azurerm_storage_account.state.name
    container_name       = azurerm_storage_container.state.name
    key                  = "dev.terraform.tfstate"
  }
}
