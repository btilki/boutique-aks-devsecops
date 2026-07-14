variable "name" {
  description = "Globally unique ACR name (alphanumeric only, 5-50 characters)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.name))
    error_message = "ACR name must be 5-50 lowercase alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Resource group hosting the registry."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "sku" {
  description = "ACR SKU (Standard sufficient for lab; Premium for private endpoint)."
  type        = string
  default     = "Standard"
}

variable "log_analytics_workspace_id" {
  description = "Optional Log Analytics workspace ID for diagnostic settings."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the registry."
  type        = map(string)
  default     = {}
}
