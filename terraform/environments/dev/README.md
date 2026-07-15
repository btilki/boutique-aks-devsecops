# Terraform environment — dev

## Purpose

Root module for the **single physical platform** (one AKS cluster hosting dev/stage/prod namespaces). Named `dev` as the Terraform environment, not the logical Boutique dev namespace.

## Usage

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init -input=false
terraform plan -input=false -out=tfplan
terraform apply -input=false tfplan
```

Full steps: [docs/setup/02-azure-foundation.md](../../../docs/setup/02-azure-foundation.md)
