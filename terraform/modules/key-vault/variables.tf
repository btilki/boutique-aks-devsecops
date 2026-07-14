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

variable "tags" {
  description = "Tags applied to the Key Vault."
  type        = map(string)
  default     = {}
}
