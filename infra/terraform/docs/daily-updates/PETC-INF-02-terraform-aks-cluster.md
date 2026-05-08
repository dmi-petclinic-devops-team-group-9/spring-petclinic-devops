# PETC-INF-02: Terraform AKS Cluster Setup

**Assigned to:** Pradeep Kumar Neelaboyina  
**Role:** Terraform Engineer  
**Date:** 08-May-2026  
**Status:** In Progress  
**Branch:** `infra/PETC-INF-02-terraform-aks-cluster`  
**Previous Branch:** `infra/PETC-INF-01-terraform-init-terraform-plan` *(Init and Plan verified)*

---

## What This Ticket Is About (Simple Version)

The previous tickets set up the **ACR** (the image storage) and verified the Terraform plan.

This ticket adds the **AKS cluster** — the actual cloud computer that will run all 8 PetClinic microservices — plus a critical permission that links AKS to ACR.

> **Lay-man analogy:**  
> - ACR is the **warehouse** where packaged goods (Docker images) are stored.  
> - AKS is the **delivery truck fleet** that picks up packages from the warehouse and delivers them (runs the services).  
> - The **role assignment** is the **access badge** that lets the truck driver into the warehouse.  
>
> Without this ticket, the trucks exist but cannot enter the warehouse.

---

## What Was Added in This Branch

Two things were added to `main.tf` and one thing was added to `outputs.tf`:

```
infra/terraform/
├── main.tf        ← Added: AKS cluster + Log Analytics + AcrPull role assignment
├── outputs.tf     ← Added: aks_name and resource_group_name outputs
├── providers.tf   ← No changes
└── variables.tf   ← No changes
```

---

## Changes to `main.tf` — Explained Block by Block

### Block 1: Log Analytics Workspace

```hcl
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.project_prefix}-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
```

**What this creates:** A logging workspace called `law-petclinic11-dev`

**What it does in plain English:**

This is Azure's version of a **black box recorder** for the cluster. Every time a pod crashes, a service restarts, or a node goes down, AKS writes a log entry here. Osman (Monitoring Engineer) can then query these logs in Azure Monitor.

| Setting | Value | Meaning |
|---|---|---|
| `name` | `law-petclinic11-dev` | The name of the workspace |
| `sku` | `PerGB2018` | Pay only for the logs you store — cheapest option |
| `retention_in_days` | `30` | Logs are kept for 30 days then deleted automatically |

> **Why does AKS need this?** Azure requires a Log Analytics workspace to be connected when you enable monitoring on an AKS cluster. Without it, the `oms_agent` block inside the AKS resource will fail.

---

### Block 2: The AKS Cluster

```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.project_prefix}-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-${var.project_prefix}-dev"

  default_node_pool {
    name       = "system"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }
}
```

**What this creates:** An AKS cluster called `aks-petclinic11-dev`

**Breaking it down section by section:**

---

#### `name` and `dns_prefix`

```hcl
name       = "aks-petclinic11-dev"
dns_prefix = "aks-petclinic11-dev"
```

- `name` — the cluster's name inside Azure
- `dns_prefix` — used to generate the public URL for the cluster's API endpoint  
  (e.g. `aks-petclinic11-dev.hcp.eastus.azmk8s.io`)

> **Lay-man:** The `dns_prefix` is like the subdomain name for your cluster. You do not use it directly — `kubectl` uses it behind the scenes.

---

#### `default_node_pool` — The Worker Machines

```hcl
default_node_pool {
  name       = "system"
  node_count = var.node_count    # = 2
  vm_size    = var.node_vm_size  # = "Standard_B2s"
}
```

**What this does:**

Creates **2 virtual machines** in Azure that act as the worker machines for Kubernetes.

| Setting | Value | Meaning |
|---|---|---|
| `name` | `system` | The name of this group of machines |
| `node_count` | `2` | How many VMs to create |
| `vm_size` | `Standard_B2s` | Each VM has 2 vCPUs and 4 GB RAM |

> **Lay-man:** If AKS is a delivery fleet, nodes are the individual delivery trucks. We have 2 trucks. Each truck has 2 engines (vCPUs) and can carry 4 GB of cargo (RAM).  
> `Standard_B2s` is a small, cheap VM — good for learning and demos, not for production traffic.

---

#### `identity` — Who Is AKS?

```hcl
identity {
  type = "SystemAssigned"
}
```

**What this does:**

Gives the AKS cluster its own **identity** in Azure Active Directory automatically.

Think of it like giving AKS an **employee ID card**. Azure uses this ID to grant or deny permissions to the cluster (like the AcrPull permission we add next).

`SystemAssigned` means: Azure creates and manages this identity automatically — we do not need to create it manually.

> **Lay-man:** Without an identity, AKS is an anonymous worker with no ID card. It cannot be given permissions because Azure does not know who it is.

---

#### `oms_agent` — Connect Monitoring

```hcl
oms_agent {
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}
```

**What this does:**

Installs a small monitoring agent inside every node of the AKS cluster. This agent sends health data, performance metrics, and container logs to the Log Analytics workspace created above.

> **Lay-man:** This is like installing a fitness tracker on every delivery truck. The tracker sends data back to the control room (Log Analytics) so Osman can see what is happening.

---

#### `network_profile` — How the Cluster Talks to the Internet

```hcl
network_profile {
  network_plugin    = "kubenet"
  load_balancer_sku = "standard"
}
```

| Setting | Value | Meaning |
|---|---|---|
| `network_plugin` | `kubenet` | Basic networking — pods get private IPs, nodes share a public IP |
| `load_balancer_sku` | `standard` | Use the Standard Azure Load Balancer (required for AKS) |

> **Lay-man:** `kubenet` is the basic road network for your cluster. `standard` load balancer is the traffic controller at the main entrance that decides which truck handles each incoming delivery request.

---

### Block 3: AcrPull Role Assignment — The Access Badge

```hcl
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
```

**What this does:**

Gives the AKS cluster **permission to download (pull) Docker images from ACR**.

Breaking it down:

| Part | Value | Meaning |
|---|---|---|
| `scope` | ACR resource ID | "This permission applies only to our ACR" |
| `role_definition_name` | `AcrPull` | "The permission is: read and pull images only" |
| `principal_id` | AKS kubelet identity ID | "The identity being granted the permission is AKS" |

> **Why `kubelet_identity` and not just `identity`?**  
> AKS has two identities:  
> - The **cluster identity** — manages cluster-level Azure resources  
> - The **kubelet identity** — runs on each node and pulls images  
>
> When Kubernetes runs a pod, it is the **kubelet** (the agent on each node) that actually calls ACR to download the image. So the AcrPull permission must be given to the kubelet identity — not the cluster identity.

> **Lay-man:** The cluster identity is the **fleet manager**. The kubelet identity is the **individual truck driver**. The driver is the one who actually drives to the warehouse (ACR) to pick up packages. So the warehouse access badge goes to the driver, not the manager.

---

## Changes to `outputs.tf`

Two new outputs were added:

```hcl
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}
```

After `terraform apply` runs, the terminal will print:

```
Outputs:

resource_group_name = "rg-petclinic11-dev"
acr_login_server    = "petclinic11acr.azurecr.io"
aks_name            = "aks-petclinic11-dev"
```

**Who needs each output:**

| Output Value | Give It To | They Need It For |
|---|---|---|
| `petclinic11acr.azurecr.io` | **Duru** | Login to ACR and push Docker images (PETC-103 onwards) |
| `aks-petclinic11-dev` | **Oladayo** | Run `az aks get-credentials` to connect kubectl (PETC-106) |
| `rg-petclinic11-dev` | **Oladayo** | Also needed in the `az aks get-credentials` command |

---

## What `terraform plan` Should Show for This Branch

After adding all the above blocks, running `terraform plan` should show:

```
Plan: 3 to add, 0 to change, 0 to destroy.
```

The 3 new resources being added:

| Resource | Azure Name |
|---|---|
| `azurerm_log_analytics_workspace.law` | `law-petclinic11-dev` |
| `azurerm_kubernetes_cluster.aks` | `aks-petclinic11-dev` |
| `azurerm_role_assignment.aks_acr_pull` | AcrPull on `petclinic11acr` |

> **Note:** The resource group and ACR were already added in PETC-INF-01.  
> If you are running `terraform plan` on the full `main.tf` (all resources together),  
> you will see `Plan: 5 to add, 0 to change, 0 to destroy` — that is also correct.

---

## Commands Run in This Branch

```bash
# 1. Make sure you are in the right folder
cd ~/DMI_Final_Project/spring-petclinic-devops/infra/terraform

# 2. Confirm you are on the correct branch
git branch
# Should show: * infra/PETC-INF-02-terraform-aks-cluster

# 3. Format the updated .tf files
terraform fmt

# 4. Validate syntax
terraform validate
# Expected: Success! The configuration is valid.

# 5. Run plan to confirm the new resources appear correctly
terraform plan
# Expected last line: Plan: 3 to add (or 5 to add if running full plan)
```

---

## Evidence Screenshots to Capture

| File | What to Screenshot |
|---|---|
| `docs/terraform-evidence/terraform-validate-INF-02.png` | Terminal showing "Success! The configuration is valid." |
| `docs/terraform-evidence/terraform-plan-INF-02.png` | Terminal showing the 3 new resources with `+` and "Plan: 3 to add" |

---

## What Has NOT Happened Yet

- `terraform apply` has **NOT** been run
- The AKS cluster **does not exist** in Azure yet
- The Log Analytics workspace **does not exist** in Azure yet
- The AcrPull role assignment **does not exist** in Azure yet

All of the above will be created in **PETC-INF-03** (`terraform apply`).

---

## Full Picture — All 5 Resources Across PETC-INF-01 and PETC-INF-02

| Resource | Added In | Azure Name |
|---|---|---|
| Resource Group | PETC-INF-01 | `rg-petclinic11-dev` |
| Azure Container Registry | PETC-INF-01 | `petclinic11acr` |
| Log Analytics Workspace | PETC-INF-02 | `law-petclinic11-dev` |
| AKS Cluster | PETC-INF-02 | `aks-petclinic11-dev` |
| AcrPull Role Assignment | PETC-INF-02 | Permission on `petclinic11acr` |

---

## Common Issues With AKS Terraform

| Problem | Error | Fix |
|---|---|---|
| VM quota exceeded | `Operation could not be completed as it results in exceeding approved standardBSFamily Cores quota` | Run `az vm list-usage --location eastus --output table` — raise a support ticket if quota is 0 |
| Node VM size not available | `The requested VM size Standard_B2s is not available` | Change `node_vm_size` in `terraform.tfvars` to `Standard_B2ms` or `Standard_DS2_v2` |
| AKS name already taken | `A resource with the ID already exists` | Change `project_prefix` in `terraform.tfvars` to a unique value |
| Role assignment already exists | `RoleAssignmentExists` | This means the permission was already given — safe to ignore or use `terraform import` |
| `oms_agent` workspace ID error | `Log Analytics Workspace not found` | Make sure the `law` resource is defined BEFORE the `aks` resource in `main.tf` |

---

## Branch and PR Summary

| Item | Value |
|---|---|
| Branch | `infra/PETC-INF-02-terraform-aks-cluster` |
| Based on | `develop` |
| Files changed | `infra/terraform/main.tf` |
| | `infra/terraform/outputs.tf` |
| | `docs/terraform-evidence/terraform-validate-INF-02.png` |
| | `docs/terraform-evidence/terraform-plan-INF-02.png` |
| | `docs/daily-updates/pradeep-terraform-engineer.md` |
| PR title | `PETC-INF-02: add AKS cluster and AcrPull role assignment to Terraform` |
| Reviewer | Benjamin Akinteye |
| Jira status | In Progress → Review |
| Next ticket | PETC-INF-03 — `terraform apply` and team handoff |

---

## Jira Comment to Add on PETC-INF-02

```
Daily update — AKS cluster Terraform code complete.

Git branch: infra/PETC-INF-02-terraform-aks-cluster
Pull Request: https://github.com/petclinic-interns/spring-petclinic-devops/pull/[NUMBER]

Work completed:
- Added azurerm_log_analytics_workspace resource to main.tf
- Added azurerm_kubernetes_cluster resource (2 nodes, Standard_B2s, SystemAssigned identity)
- Added oms_agent block to connect AKS monitoring to Log Analytics
- Added azurerm_role_assignment (AcrPull) — gives AKS permission to pull from ACR
- Added aks_name and resource_group_name to outputs.tf
- Ran terraform validate — Success! The configuration is valid.
- Ran terraform plan — Plan: 3 to add, 0 to change, 0 to destroy
- Saved validate and plan screenshots to docs/terraform-evidence/

Blockers: None
Next plan:
- Wait for PR approval from Benjamin
- Move to PETC-INF-03 — run terraform apply and share outputs with Duru and Oladayo

Status: In Progress → Review
```

---

*PETC-INF-02 | Branch: infra/PETC-INF-02-terraform-aks-cluster | Terraform Engineer: Pradeep Kumar Neelaboyina | Group 9 | May 2026*
