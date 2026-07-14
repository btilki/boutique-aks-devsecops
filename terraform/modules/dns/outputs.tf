output "zone_id" {
  description = "DNS zone ARM ID."
  value       = azurerm_dns_zone.this.id
}

output "zone_name" {
  description = "DNS zone name."
  value       = azurerm_dns_zone.this.name
}

output "name_servers" {
  description = "Azure DNS name servers — delegate at domain registrar."
  value       = azurerm_dns_zone.this.name_servers
}
