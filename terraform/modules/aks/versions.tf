# Provider pin for standalone `terraform validate` (pre-commit) in this module directory.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}
