output "vnet_id" {
  description = "Virtual network ARM ID."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.this.name
}

output "aks_subnet_id" {
  description = "AKS subnet ARM ID (used by Topic 03 AKS module)."
  value       = azurerm_subnet.aks.id
}

output "aks_subnet_name" {
  description = "AKS subnet name."
  value       = azurerm_subnet.aks.name
}

output "aks_nsg_id" {
  description = "NSG ARM ID associated with the AKS subnet."
  value       = azurerm_network_security_group.aks.id
}
