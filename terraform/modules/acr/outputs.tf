output "id" {
  description = "ACR ARM ID."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "ACR registry name."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "ACR login server FQDN."
  value       = azurerm_container_registry.this.login_server
}
