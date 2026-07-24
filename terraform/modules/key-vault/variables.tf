variable "name" {
  description = "Key Vault name (3-24 characters, alphanumeric and hyphens)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.name))
    error_message = "Key Vault name must be 3-24 characters (alphanumeric and hyphens)."
  }
}

variable "resource_group_name" {
  description = "Resource group hosting the Key Vault."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Optional Log Analytics workspace ID for diagnostic settings."
  type        = string
  default     = null
}

variable "purge_protection_enabled" {
  description = "Enable purge protection. Default false for cheap teardown; set true for long-lived envs (Topic 19). Soft-delete remains on."
  type        = bool
  default     = false
}

variable "network_acls_default_action" {
  description = "Key Vault network ACL default action: Allow (pilot default) or Deny (Topic 19 harden)."
  type        = string
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls_default_action)
    error_message = "network_acls_default_action must be Allow or Deny."
  }
}

variable "network_acls_bypass" {
  description = "Network ACL bypass (AzureServices recommended for platform integrations)."
  type        = string
  default     = "AzureServices"
}

variable "network_acls_ip_rules" {
  description = "Optional public IPv4 allow-list when default_action is Deny (e.g. operator / ADO Microsoft-hosted — prefer subnet allow for AKS)."
  type        = list(string)
  default     = []
}

variable "network_acls_subnet_ids" {
  description = "Subnet IDs allowed to reach Key Vault when default_action is Deny (AKS subnet with Microsoft.KeyVault service endpoint)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the Key Vault."
  type        = map(string)
  default     = {}
}
