# PETC-INF-01: Terraform Init and Terraform Plan

**Assigned to:** Pradeep Kumar Neelaboyina  
**Role:** Terraform Engineer  
**Date:** 08-May-2026  
**Status:** In Progress  
**Branch:** `infra/PETC-INF-01-terraform-init-terraform-plan`  
**Previous Branch:** `infra/PETC-INF-01-terraform-acr` *(Terraform files created)*  

---

## What This Branch Is About (Simple Version)

The previous branch created the Terraform recipe files (`.tf` files).  
This branch is about **running two safety checks before anything is created in Azure**.

Think of it like this:

> **Lay-man analogy:**  
> Before a chef starts cooking, they do two things:  
> 1. **Gather all the ingredients** (`terraform init`)  
> 2. **Read the recipe out loud to confirm it makes sense** (`terraform plan`)  
>
> Only after both steps are done does the chef actually start cooking (`terraform apply` — next step).

Nothing in Azure has been created yet. This branch is purely **preparation and verification**.

---

## Two Commands Run in This Branch

### Command 1: `terraform init`

```bash
terraform init
```

**What this command does:**

Terraform reads your `.tf` files and downloads everything it needs to talk to Azure.

Specifically it:
- Downloads the **AzureRM provider plugin** (the connector between Terraform and Azure)
- Creates a hidden `.terraform/` folder with that plugin inside
- Creates a `.terraform.lock.hcl` file that records the exact plugin version used

**What the terminal output looks like:**

```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 4.0"...
- Installing hashicorp/azurerm v4.x.x...
- Installed hashicorp/azurerm v4.x.x

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan"
to see any changes that are required for your infrastructure.
```

**What "successfully initialized" means:**

Terraform is now connected to Azure and ready to work. If you see any red errors here, stop and fix them before continuing.

> **Important:** The `.terraform/` folder and `.terraform.lock.hcl` are **NOT committed** to Git.  
> They are already blocked in `.gitignore`. Only your `.tf` source files go to GitHub.

---

### Command 2: `terraform plan`

```bash
terraform plan
```

**What this command does:**

Terraform reads your `.tf` files, connects to Azure, and then **shows you exactly what it will create** — without actually creating anything yet.

Think of it as a **preview** or a **dry run**.

**What the terminal output looks like:**

```
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_resource_group.rg will be created
  + resource "azurerm_resource_group" "rg" {
      + id       = (known after apply)
      + location = "eastus"
      + name     = "rg-petclinic11-dev"
    }

  # azurerm_container_registry.acr will be created
  + resource "azurerm_container_registry" "acr" {
      + admin_enabled       = false
      + id                  = (known after apply)
      + location            = "eastus"
      + login_server        = (known after apply)
      + name                = "petclinic11acr"
      + resource_group_name = "rg-petclinic11-dev"
      + sku                 = "Basic"
    }

  # azurerm_log_analytics_workspace.law will be created
  + resource "azurerm_log_analytics_workspace" "law" {
      + id                  = (known after apply)
      + location            = "eastus"
      + name                = "law-petclinic11-dev"
      + resource_group_name = "rg-petclinic11-dev"
      + retention_in_days   = 30
      + sku                 = "PerGB2018"
    }

  # azurerm_kubernetes_cluster.aks will be created
  + resource "azurerm_kubernetes_cluster" "aks" {
      + dns_prefix          = "aks-petclinic11-dev"
      + id                  = (known after apply)
      + location            = "eastus"
      + name                = "aks-petclinic11-dev"
      + resource_group_name = "rg-petclinic11-dev"
    }

  # azurerm_role_assignment.aks_acr_pull will be created
  + resource "azurerm_role_assignment" "aks_acr_pull" {
      + id                   = (known after apply)
      + principal_id         = (known after apply)
      + role_definition_name = "AcrPull"
      + scope                = (known after apply)
    }

Plan: 5 to add, 0 to change, 0 to destroy.
```

**Reading the plan output — what each symbol means:**

| Symbol | Meaning |
|---|---|
| `+` green | This resource will be **created** — it does not exist yet |
| `~` yellow | This resource will be **updated** — it already exists |
| `-` red | This resource will be **destroyed** — it will be deleted |
| `(known after apply)` | This value will only be known once the resource is actually created |

**The most important line is at the bottom:**

```
Plan: 5 to add, 0 to change, 0 to destroy.
```

This means Terraform will create **5 new resources** and will not touch or delete anything else. This is exactly what we expect.

> **Why show the team this output before applying?**  
> If you ran `terraform apply` directly without checking the plan, you could accidentally delete or change something. The plan is your last chance to review before any real action happens in Azure.

---

## What the 5 Resources Are

The plan output confirms all 5 resources Terraform will create:

| # | Resource Name in Azure | What It Is |
|---|---|---|
| 1 | `rg-petclinic11-dev` | Resource Group — the project folder in Azure |
| 2 | `petclinic11acr` | Azure Container Registry — where Docker images are stored |
| 3 | `law-petclinic11-dev` | Log Analytics Workspace — stores AKS health logs |
| 4 | `aks-petclinic11-dev` | AKS Cluster — the cloud machine that runs all 8 services |
| 5 | `AcrPull` Role Assignment | Gives AKS permission to pull images from ACR |

---

## What Was Committed in This Branch

The following file was added as evidence of the `terraform init` and `terraform plan` outputs:

```
spring-petclinic-devops/
└── docs/
    └── terraform-evidence/
        ├── terraform-init-output.png      ← Screenshot of successful init
        ├── terraform-plan-output.png      ← Screenshot of plan showing 5 to add
        └── pradeep-terraform-engineer.md  ← This daily update file
```

> **Note:** No `.tf` files were changed in this branch.  
> The Terraform source files were committed in the previous branch:  
> `infra/PETC-INF-01-terraform-acr`

---

## Commands Run Step by Step

```bash
# 1. Navigate into the terraform folder inside the repo
cd ~/DMI_Final_Project/spring-petclinic-devops/infra/terraform

# 2. Initialise Terraform (download the Azure provider plugin)
terraform init

# 3. Format the .tf files neatly (optional but good practice)
terraform fmt

# 4. Check for any syntax errors in the .tf files
terraform validate
# Expected output: Success! The configuration is valid.

# 5. Preview what Terraform will create — review before sharing with team
terraform plan
# Expected last line: Plan: 5 to add, 0 to change, 0 to destroy.
```

---

## Evidence Screenshots Captured

| Screenshot File | What It Shows |
|---|---|
| `docs/terraform-evidence/terraform-init-output.png` | Terminal showing "Terraform has been successfully initialized!" |
| `docs/terraform-evidence/terraform-plan-output.png` | Terminal showing all 5 resources with `+` symbols and "Plan: 5 to add" |

---

## What Has NOT Happened Yet

- `terraform apply` has **NOT** been run
- **No resources have been created** in Azure yet
- The resource group, ACR, AKS cluster, and Log Analytics workspace **do not exist yet**

That is the next step — `terraform apply` — which will be done in the next ticket or task once the team has reviewed and approved this plan output.

---

## What the Team Needs to Do Before `terraform apply`

1. **Benjamin** — review this PR and approve it
2. **Ikedimma** — confirm the plan output looks correct (5 to add, 0 to destroy)
3. **Pradeep** — once PR is approved, run `terraform apply` and share outputs with Duru and Oladayo

---

## Next Steps After This PR Is Merged

Once `terraform apply` is run successfully:

| Who Gets What | Value | Why They Need It |
|---|---|---|
| **Duru** | `acr_login_server` output | She needs it to push Docker images (PETC-103 onwards) |
| **Oladayo** | `aks_name` + `resource_group_name` | He needs them to connect `kubectl` to the cluster (PETC-106 onwards) |

---

## Common Issues During `terraform init` and `terraform plan`

| Problem | Error Message | Fix |
|---|---|---|
| Not logged in to Azure | `Error: building AzureRM Client` | Run `az login` first, then retry |
| Wrong subscription active | Resources go to the wrong account | Run `az account show` to check, then `az account set --subscription "NAME"` |
| `terraform.tfvars` missing | `No value for required variable "project_prefix"` | Create `terraform.tfvars` locally with `project_prefix = "petclinic11"` — do NOT commit this file |
| Provider version conflict | `Error: Failed to query available provider packages` | Delete the `.terraform/` folder and run `terraform init` again |
| Quota error during plan | `Error: compute.VirtualMachinesClient#CreateOrUpdate: Insufficient quota` | This only appears at apply time — plan will still succeed |

---

## Branch and PR Summary

| Item | Value |
|---|---|
| Branch | `infra/PETC-INF-01-terraform-init-terraform-plan` |
| Based on | `develop` |
| Files changed | `docs/terraform-evidence/terraform-init-output.png` |
| | `docs/terraform-evidence/terraform-plan-output.png` |
| | `docs/daily-updates/pradeep-terraform-engineer.md` |
| PR title | `PETC-INF-01: terraform init and plan — 5 resources verified` |
| Reviewer | Benjamin Akinteye |
| Jira status | In Progress |
| Next action | Wait for PR approval, then run `terraform apply` |

---

## Jira Comment to Add on PETC-INF-01

```
Daily update — terraform init and plan completed.

Git branch: infra/PETC-INF-01-terraform-init-terraform-plan
Pull Request: https://github.com/petclinic-interns/spring-petclinic-devops/pull/[NUMBER]

Work completed:
- Ran terraform init — Azure provider downloaded successfully
- Ran terraform validate — configuration is valid
- Ran terraform plan — output shows Plan: 5 to add, 0 to change, 0 to destroy
- Saved init and plan screenshots to docs/terraform-evidence/
- No resources created in Azure yet — waiting for team review

Blockers: None
Next plan: Run terraform apply once this PR is approved

Status: In Progress → Review
```

---

*PETC-INF-01 | Branch: infra/PETC-INF-01-terraform-init-terraform-plan | Terraform Engineer: Pradeep Kumar Neelaboyina | Group 9 | May 2026*
