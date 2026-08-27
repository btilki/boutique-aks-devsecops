# Provider pin for standalone `terraform validate` in this module directory.
# Root stacks (bootstrap, environments/dev) lock azurerm 3.117.1 (~> 3.100).
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}
