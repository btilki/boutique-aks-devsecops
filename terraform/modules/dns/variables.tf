variable "resource_group_name" {
  description = "Resource group that hosts the DNS zone."
  type        = string
}

variable "zone_name" {
  description = "Public DNS zone name (e.g. biroltilki.art)."
  type        = string
}

variable "tags" {
  description = "Tags applied to the DNS zone."
  type        = map(string)
  default     = {}
}
