# PETC-INF-01: Terraform ACR Setup

**Assigned to:** Pradeep Kumar Neelaboyina  
**Role:** Terraform Engineer  
**Date:** 08-May-2026  
**Status:** In Progress  
**Branch:** `infra/PETC-INF-01-terraform-acr`

---

## What Is This Ticket About? (Simple Version)

Think of this ticket like **setting up a private photo album in the cloud**.

Before our team can run the PetClinic app on Azure, someone needs to:

1. Create a **storage place for our Docker images** (called ACR — Azure Container Registry)
2. Write that setup as **code** so anyone can recreate it exactly the same way

That is what Terraform does — instead of clicking buttons in the Azure website 30 times, we write a recipe (code) once, and Terraform creates everything automatically.

> **Lay-man analogy:** Terraform is like a shopping list + a robot. You write the list, the robot goes and buys everything exactly as written. Every single time. No mistakes.

---

## Why Does This Ticket Matter to the Team?

Without this ticket being done, **Duru cannot push Docker images** and **Oladayo cannot deploy to AKS**.

The order is:
```
Pradeep creates ACR  →  Duru pushes images to ACR  →  AKS pulls images from ACR  →  App runs
```

This ticket is the **first domino**. Everything else depends on it.

---

## What Is ACR? (Azure Container Registry)

ACR is like a **private app store for Docker images**.

- Docker images are packaged versions of each microservice (config-server, api-gateway, etc.)
- ACR stores those images safely in Azure
- When Kubernetes (AKS) needs to run a service, it pulls the image from ACR

Without ACR:
- Duru has nowhere to push the images she builds
- AKS has nothing to pull and run

---

## Files Created in This Ticket

All files live inside the repo at: `infra/terraform/`

```
spring-petclinic-devops/
└── infra/
    └── terraform/
        ├── providers.tf      ← Tells Terraform to use Azure
        ├── variables.tf      ← Defines input settings (like project name)
        ├── main.tf           ← The actual Azure resources to create
        └── outputs.tf        ← Prints useful info after creation
```

> **Note:** `terraform.tfvars` is intentionally NOT in the repo.  
> It contains your group name/prefix and could hold secrets — it is listed in `.gitignore`.

---

## File-by-File Explanation

### 1. `providers.tf` — "Which cloud are we using?"

```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

**What this does in plain English:**

- `terraform { required_version }` → "I need Terraform version 1.6 or newer installed"
- `required_providers { azurerm }` → "I am going to use Microsoft Azure — download the Azure plugin"
- `provider "azurerm" { features {} }` → "Connect to Azure using my logged-in account"

> **Lay-man:** This file is like plugging the right power adapter into the socket before you start any work.

---

### 2. `variables.tf` — "What are the settings I can change?"

```hcl
variable "project_prefix" {
  description = "Short lowercase project prefix, e.g. petclinic11"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "node_count" {
  description = "Number of AKS worker nodes"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "AKS node VM size"
  type        = string
  default     = "Standard_B2s"
}
```

**What this does in plain English:**

- Instead of hardcoding `petclinic11` everywhere, we put it in a variable
- If the group name changes, we change it in **one place** and everything updates
- `default = "eastus"` means: unless told otherwise, create resources in the East US region

| Variable | Meaning | Example Value |
|---|---|---|
| `project_prefix` | Your group's short name | `petclinic11` |
| `location` | Which Azure data centre | `eastus` |
| `node_count` | How many machines in AKS | `2` |
| `node_vm_size` | Size of each machine | `Standard_B2s` |

> **Lay-man:** Variables are like blanks in a form. You fill in your group's details once, and the whole document updates.

---

### 3. `main.tf` — "The actual things to create in Azure"

This is the most important file. It tells Terraform exactly what to build.

```hcl
# 1. A container (folder) for all our Azure resources
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_prefix}-dev"
  location = var.location
}
```

**What this creates:** A resource group called `rg-petclinic11-dev`

> Think of a resource group like a **project folder** in Azure. Everything we create goes inside it.

---

```hcl
# 2. The private Docker image storage (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "${var.project_prefix}acr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}
```

**What this creates:** An ACR called `petclinic11acr`

> This is the private app store where Duru pushes all 8 Docker images.  
> `sku = "Basic"` means we use the cheapest tier — fine for learning/demo.

---

```hcl
# 3. A logging workspace so Azure can monitor the cluster
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.project_prefix}-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
```

**What this creates:** A log storage workspace called `law-petclinic11-dev`

> Think of this like a **CCTV recording storage**. AKS sends all its health logs here so Osman can monitor them in Azure Monitor.

---

```hcl
# 4. The Kubernetes cluster itself (AKS)
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

**What this creates:** An AKS cluster called `aks-petclinic11-dev` with 2 worker machines

> This is the cloud computer cluster where all 8 PetClinic microservices will run.  
> `node_count = 2` means Azure gives us 2 virtual machines to run our containers on.

---

```hcl
# 5. Permission: allow AKS to pull images from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
```

**What this does:** Gives the AKS cluster permission to download images from ACR

> Without this permission, AKS would say "Access Denied" every time it tried to pull a Docker image.  
> Think of it like giving AKS a **key card** to enter the ACR building.

---

### 4. `outputs.tf` — "Print useful info after Terraform finishes"

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

**What this does in plain English:**

After `terraform apply` finishes, the terminal prints:

```
resource_group_name = "rg-petclinic11-dev"
acr_login_server    = "petclinic11acr.azurecr.io"
aks_name            = "aks-petclinic11-dev"
```

> These three values are **critical handoff info**:
> - Give `acr_login_server` to **Duru** → she needs it to push images
> - Give `aks_name` to **Oladayo** → he needs it to connect kubectl

---

## The `.gitignore` Entries Added

The following was appended to `.gitignore` at the project root:

```
# Terraform
.terraform/
*.tfstate
*.tfstate.backup
terraform.tfvars
.terraform.lock.hcl
# Secrets
.env
*.env.local
```

**Why each entry is blocked:**

| Entry | Why It Must Never Be Committed |
|---|---|
| `.terraform/` | Large auto-downloaded folder — not source code |
| `*.tfstate` | Contains the LIVE state of your Azure infrastructure — can contain secrets |
| `*.tfstate.backup` | Backup of the above — same risk |
| `terraform.tfvars` | Contains your group prefix — can contain real passwords if added later |
| `.terraform.lock.hcl` | Auto-generated lock file — recreated by `terraform init` |
| `.env` | Local environment variables — often contains API keys |
| `*.env.local` | Same — local secrets file |

---

## Commands to Run (In This Order)

Once the files are in place inside `infra/terraform/`, run these from that folder:

```bash
# Step 1: Download the Azure plugin
terraform init

# Step 2: Format the files neatly
terraform fmt

# Step 3: Check for syntax errors
terraform validate

# Step 4: Preview what will be created (DO NOT apply yet — show the team first)
terraform plan

# Step 5: Actually create everything in Azure (only after team review)
terraform apply
# Type: yes
```

> **Important:** Run `terraform plan` first and screenshot the output.  
> Share it with the team in Jira before running `terraform apply`.  
> This is a safety check — plan shows what WILL happen, apply actually does it.

---

## What to Screenshot as Evidence

| Screenshot | Where to Save |
|---|---|
| `terraform validate` — showing "Success! The configuration is valid." | `docs/terraform-evidence/validate-output.png` |
| `terraform plan` — showing list of resources to be created | `docs/terraform-evidence/plan-output.png` |
| `terraform apply` — showing "Apply complete! Resources: 5 added" | `docs/terraform-evidence/apply-output.png` |
| Azure Portal → Resource Group → showing all 4 resources | `docs/terraform-evidence/azure-portal-rg.png` |
| Azure Portal → ACR → Repositories page | `docs/terraform-evidence/azure-acr-portal.png` |

---

## Handoff Checklist After `terraform apply`

- [ ] Share `acr_login_server` value with **Duru** (she needs it for PETC-103)
- [ ] Share `aks_name` and `resource_group_name` with **Oladayo** (he needs it for PETC-106)
- [ ] Commit all `.tf` files to the feature branch
- [ ] Open Pull Request → assign reviewer: **Benjamin Akinteye**
- [ ] Add PR link as comment on Jira ticket PETC-INF-01
- [ ] Move Jira ticket status: `In Progress → Review`

---

## Common Errors and Fixes

| Error Message | What It Means | Fix |
|---|---|---|
| `Error: A resource with the ID already exists` | ACR or AKS name is already taken in Azure | Change `project_prefix` in `terraform.tfvars` to something unique |
| `Error: Insufficient quota` | Your Azure subscription hit its VM limit | Run `az vm list-usage --location eastus --output table` to check, then raise a support ticket |
| `Error: The client does not have authorization` | You are not logged in to Azure | Run `az login` first |
| `Error: Invalid character in name` | ACR name has uppercase letters or hyphens | ACR names must be **lowercase letters and numbers only** — no hyphens |
| `terraform: command not found` | Terraform is not installed | Run `brew install hashicorp/tap/terraform` on macOS |

---

## Summary — What This Ticket Does in One Sentence

> This ticket uses Terraform code to automatically create the Azure Container Registry (image storage) and AKS cluster (app runner) that the entire Group-9 project depends on.

---

*PETC-INF-01 | Terraform Engineer: Pradeep Kumar Neelaboyina | Group 9 | May 2026*
