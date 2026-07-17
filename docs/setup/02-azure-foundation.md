# 02 — Azure Foundation

**Audience:** L2 — Implementer
**Estimated time:** 90 minutes (plus DNS propagation wait)
**Prerequisites:** [01-terraform-bootstrap.md](01-terraform-bootstrap.md) ✅ complete
**Creates:** Platform resource group, VNet + AKS subnet + NSG, Azure DNS zone `biroltilki.art`
**Related ADRs:** [0001 — Azure cloud provider](../adr/0001-azure-cloud-provider.md), [0012 — Loki in-cluster logging](../adr/0012-loki-in-cluster-logging.md)

---

## Topic goal

When this topic is complete, the **platform resource group** exists in `germanywestcentral` with a VNet (`10.0.0.0/16`), an AKS-ready subnet (`10.0.0.0/20`) with NSG, and an Azure DNS zone for `biroltilki.art`. DNS is **delegated** at your registrar to Azure name servers so cert-manager DNS-01 can succeed in Topic 06.

## Why this topic is required

AKS (Topic 03) requires a subnet ID and resource group. Ingress TLS (Topic 06) requires Azure DNS control of `biroltilki.art`. Logs run in-cluster via Loki (Topic 11, ADR-0012) — no Log Analytics workspace in this topic. Applying foundation separately keeps `terraform plan` reviewable and limits blast radius if networking or DNS values are wrong.

---

## Before you begin

- [ ] Topic 01 complete: remote backend works (`terraform init` in `environments/dev`)
- [ ] `az account show` targets the correct subscription
- [ ] You control DNS at the **registrar** for `biroltilki.art` (or a subdomain delegation plan)
- [ ] You understand this `apply` creates **billable** Azure resources (VNet is free; no Log Analytics per ADR-0012)

```bash
cd terraform/environments/dev
terraform init -input=false
az account show --query "{name:name, id:id}" -o table
```

---

## Step 2.1: Review modules and variables

### Goal

Confirm Topic 02 Terraform sources and addressing match the architecture before `apply`.

### Why this step is required

VNet CIDR and DNS zone name are hard to change after AKS is deployed. Review now avoids rework in Topic 03.

### Commands

```bash
cd /path/to/boutique-aks-devsecops
cat terraform/environments/dev/terraform.tfvars.example
cat docs/architecture/06-network-design.md | head -40
ls terraform/modules/{resource-group,networking,dns}/
```

### Expected output

| Setting | Locked value |
|---------|--------------|
| `location` | `germanywestcentral` |
| `vnet_address_space` | `10.0.0.0/16` |
| `aks_subnet_prefixes` | `10.0.0.0/20` |
| `dns_zone_name` | `biroltilki.art` |

### Validation

- [ ] Three modules have `main.tf`, `variables.tf`, `outputs.tf`
- [ ] `main.tf` in dev env wires only RG, networking, DNS (no AKS yet)

### Security notes

- NSG allows Azure Load Balancer and VNet inbound; no public SSH to nodes (AKS manages nodes)

---

## Step 2.2: Create dev terraform.tfvars

### Goal

Provide environment-specific names for the platform resource group.

### Why this step is required

RG names must be unique within your subscription; values stay out of Git.

### Commands

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` — at minimum confirm:

- `resource_group_name = "rg-boutique-dev-gwc"`

### Validation

- [ ] `terraform.tfvars` exists and is **not** tracked by Git
- [ ] `location` remains `germanywestcentral`

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| RG name conflict | Prior test deployment | Choose `rg-boutique-dev-gwc2` or similar |

---

## Step 2.3: Initialize Terraform with remote backend

### Goal

Ensure provider plugins and remote state backend are ready for plan/apply.

### Why this step is required

Topic 01 may have been run on another machine; re-init syncs backend and providers.

### Commands

```bash
cd terraform/environments/dev
terraform init -input=false -upgrade
```

### Expected output

```text
Terraform has been successfully initialized!
```

### Validation

```bash
terraform providers
```

- [ ] `azurerm` provider `~> 3.100` resolved

### Recovery

If backend auth fails, see [01-terraform-bootstrap.md](01-terraform-bootstrap.md) Step 1.8 (Storage Blob Data Contributor).

---

## Step 2.4: Plan foundation apply

### Goal

Preview all Topic 02 resources before creation.

### Why this step is required

First real platform `apply` — verify ~6–8 resources match expectations.

### Commands

```bash
cd terraform/environments/dev
terraform plan -input=false -out=tfplan
```

### Expected output

Plan adds resources similar to:

- `module.resource_group.azurerm_resource_group.this`
- `module.networking.azurerm_virtual_network.this`
- `module.networking.azurerm_subnet.aks`
- `module.networking.azurerm_network_security_group.aks`
- `module.networking.azurerm_subnet_network_security_group_association.aks`
- `module.dns.azurerm_dns_zone.this`

**Plan:** approximately **6 to add**, 0 change, 0 destroy (first apply).

### Validation

- [ ] All resources in `rg-boutique-dev-gwc` (or your RG name)
- [ ] Location `germanywestcentral` throughout
- [ ] No AKS, ACR, or Key Vault in plan (those are Topic 03)

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `AuthorizationFailed` | RBAC | Contributor on subscription or RG scope |
| Unexpected destroy | State drift | Do not apply; investigate state file |

### Cost impact

- VNet/subnet/NSG/DNS zone: negligible
- No Log Analytics workspace (ADR-0012)

---

## Step 2.5: Apply foundation stack

### Goal

Create platform networking and DNS zone in Azure.

### Why this step is required

Downstream topics depend on `aks_subnet_id` and DNS zone outputs.

### Commands

```bash
cd terraform/environments/dev
terraform apply -input=false tfplan
```

### Expected output

```text
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```

Capture outputs:

```bash
terraform output
terraform output -json dns_name_servers
```

### Validation

- [ ] Apply exits 0
- [ ] `terraform output aks_subnet_id` is non-empty
- [ ] `terraform output dns_name_servers` lists 4 Azure NS hostnames

### Recovery

If apply fails mid-way:

```bash
terraform plan -input=false
terraform apply -input=false
```

To destroy **only** Topic 02 resources before Topic 03 (⚠️):

```bash
terraform destroy -input=false
```

Only if AKS has not been added yet.

---

## Step 2.6: Verify resources in Azure Portal

### Goal

Confirm resources exist in the correct subscription and region.

### Why this step is required

Catches wrong-subscription applies before DNS delegation.

### GUI instructions

1. Navigate to: **Azure Portal** → **Resource groups** → **`rg-boutique-dev-gwc`**
2. Confirm resources:

| Resource type | Expected name |
|---------------|---------------|
| Virtual network | `vnet-boutique-dev-gwc` |
| DNS zone | `biroltilki.art` |
| Network security group | `aks-subnet-nsg` |

3. Click **DNS zone** → **Overview** → copy **Name servers** list

### CLI validation

```bash
az group show -n rg-boutique-dev-gwc -o table
az network vnet show -g rg-boutique-dev-gwc -n vnet-boutique-dev-gwc --query "{name:name, prefixes:addressSpace.addressPrefixes}" -o json
az network dns zone show -g rg-boutique-dev-gwc -n biroltilki.art --query "{name:name, nameservers:nameServers}" -o json
```

### Validation

- [ ] All three CLI commands succeed
- [ ] VNet address space is `10.0.0.0/16`

---

## Step 2.7: Delegate DNS at domain registrar

### Goal

Point `biroltilki.art` (or relevant zone) to Azure DNS name servers.

### Why this step is required

Without delegation, `dig NS biroltilki.art` will not show Azure servers and cert-manager DNS-01 will fail in Topic 06.

### Commands

Get name servers from Terraform:

```bash
cd terraform/environments/dev
terraform output -json dns_name_servers
```

### GUI instructions (registrar — example flow)

**Platform:** Your domain registrar (e.g. Namecheap, Cloudflare Registrar, GoDaddy)

1. Log in to registrar account for **`biroltilki.art`**
2. Navigate to: **Domain** → **DNS** or **Nameservers**
3. Choose **Custom nameservers** (not registrar parking DNS)
4. Set **exactly** the four Azure name servers from `terraform output`, for example:

| # | Nameserver |
|---|------------|
| 1 | `ns1-XX.azure-dns.com.` |
| 2 | `ns2-XX.azure-dns.net.` |
| 3 | `ns3-XX.azure-dns.org.` |
| 4 | `ns4-XX.azure-dns.info.` |

5. Save changes
6. Wait for propagation (often 15–60 minutes; up to 48 hours)

**Permissions:** Registrar account with permission to change NS records.

**Verification:** Registrar UI shows custom Azure nameservers saved.

### Security notes

- Do not delegate a production corporate zone without change approval
- Record old NS values for rollback

### Recovery

Revert to previous nameservers at registrar if you must roll back.

---

## Step 2.8: Validate DNS delegation

### Goal

Confirm the public internet resolves `biroltilki.art` to Azure DNS.

### Why this step is required

Early validation avoids debugging TLS failures days later.

### Commands

```bash
dig NS biroltilki.art +short
dig SOA biroltilki.art +short
```

### Expected output

`dig NS` returns four `*.azure-dns.*` hostnames (may take time after Step 2.7).

### Validation

- [ ] NS records include `azure-dns.com`, `azure-dns.net`, etc.
- [ ] Optional: `az network dns record-set ns show -g rg-boutique-dev-gwc -z biroltilki.art -n @` succeeds

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Old NS still showing | TTL / propagation | Wait; flush local DNS cache |
| Partial NS list | Registrar typo | Fix nameserver hostnames exactly |
| `NXDOMAIN` | Wrong zone | Confirm zone name in tfvars |

---

## Step 2.9: Run repository Terraform validation

### Goal

Confirm repo Terraform passes fmt and validate checks.

### Why this step is required

Establishes CI/local gate used before every PR.

### Commands

```bash
cd /path/to/boutique-aks-devsecops
chmod +x tests/terraform/validate.sh
./tests/terraform/validate.sh
```

### Expected output

```text
[validate] terraform fmt -check -recursive
[validate] bootstrap module
Success! The configuration is valid.
[validate] dev environment (Topic 02 modules only)
Success! The configuration is valid.
[validate] OK
```

### Validation

- [ ] Script exits 0

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `fmt -check` failed | Unformatted `.tf` | Run `terraform fmt -recursive terraform/` |

---

## Topic validation (end-to-end)

```bash
cd terraform/environments/dev
terraform output
./../../tests/terraform/validate.sh
dig NS biroltilki.art +short
```

**Success criteria:**

- [ ] Terraform outputs: `aks_subnet_id`, `dns_name_servers`
- [ ] Azure Portal shows RG + VNet + DNS zone
- [ ] NS delegation propagated (or documented wait if in progress)
- [ ] `tests/terraform/validate.sh` passes

Update [Setup Index](README.md) Topic 02 to ✅ when complete.

**Do not proceed to Topic 03** until NS delegation is confirmed or you accept TLS delay risk and document expected wait time.

---

## Topic troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `terraform plan` wants to recreate VNet | Changed address space | Do not change CIDR after apply; destroy/recreate only if no AKS |
| DNS zone already exists in another RG | Prior deployment | Import zone or use existing zone via refactor (out of scope) |

---

## Next step

➡️ Continue to **[03-cluster-resources.md](03-cluster-resources.md)** (Topic 03) after Topic 02 validation.

Topic 03 extends `terraform/environments/dev/main.tf` with AKS, ACR, and Key Vault modules using `aks_subnet_id` from this topic.
