# Terraform bootstrap

## Purpose

Provision Azure Storage for Terraform remote state (container + optional locking).

## Prerequisites

- Azure subscription owner/contributor
- [docs/setup/01-terraform-bootstrap.md](../../docs/setup/01-terraform-bootstrap.md)

## Usage

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars   # set unique storage_account_name
terraform init -input=false
terraform plan -input=false -out=tfplan
terraform apply -input=false tfplan
terraform output
```

Then initialize the dev backend: `cd ../environments/dev && terraform init -input=false`

Full steps: [docs/setup/01-terraform-bootstrap.md](../../docs/setup/01-terraform-bootstrap.md)

## Timing

SETUP_REQUIRED — Phase 1.
