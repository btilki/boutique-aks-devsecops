variable "resource_group_name" {
  description = "Resource group that hosts the Log Analytics workspace."
  type        = string
}

variable "location" {
  description = "Azure region for the workspace."
  type        = string
}

variable "workspace_name" {
  description = "Log Analytics workspace name."
  type        = string
}

variable "sku" {
  description = "Log Analytics workspace SKU."
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Log retention in days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to the workspace."
  type        = map(string)
  default     = {}
}
