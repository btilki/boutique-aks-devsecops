# Remote backend for the dev environment root module (single physical AKS platform).
# Values must match terraform/bootstrap outputs after bootstrap apply.
# Update literals if you used different names in terraform/bootstrap/terraform.tfvars.
# See docs/setup/01-terraform-bootstrap.md Step 1.8.

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-boutique-gwc"
    storage_account_name = "stboutiquetfgwc"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
