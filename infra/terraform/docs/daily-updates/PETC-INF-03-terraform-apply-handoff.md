# PETC-INF-03: Terraform Apply and Team Handoff

**Assigned to:** Pradeep Kumar Neelaboyina  
**Role:** Terraform Engineer  
**Date:** 08-May-2026  
**Status:** Done  
**Branch:** `infra/PETC-INF-03-terraform-apply-handoff`  
**Previous Branch:** `infra/PETC-INF-02-terraform-aks-cluster`

---

## What This Ticket Is About (Simple Version)

The previous two tickets wrote the Terraform code and verified the plan.
This ticket is the final step — actually pressing the button and creating everything in Azure.

Lay-man analogy:
- PETC-INF-01 wrote the recipe
- PETC-INF-02 read the recipe out loud and confirmed it made sense
- PETC-INF-03 actually cooked the meal — and now the kitchen is open for the whole team

After this ticket, the Azure infrastructure is live and ready. Every other team member can now start their work.

---

## Command Run

```bash
terraform apply -auto-approve
```

What `-auto-approve` does: skips the manual yes/no confirmation prompt and applies immediately.
Safe to use here because we already reviewed and approved the plan in PETC-INF-01.

---

## Full terraform apply Output — What Happened and When

### Resource 1 — Resource Group

```
azurerm_resource_group.rg: Creating...
azurerm_resource_group.rg: Still creating... [00m10s elapsed]
azurerm_resource_group.rg: Still creating... [00m20s elapsed]
azurerm_resource_group.rg: Creation complete after 26s
[id=/subscriptions/02a63bd0-9d00-4914-a99e-3c218379f2bf/resourceGroups/rg-petclinic11-dev]
```

**Created:** `rg-petclinic11-dev` in `westeurope`
**Time taken:** 26 seconds
**What it is:** The Azure project folder. Every other resource lives inside this group.
**Why it ran first:** All other resources depend on the resource group existing — Terraform knew this automatically.

---

### Resource 2 — Azure Container Registry (ACR)

```
azurerm_container_registry.acr: Creating...
azurerm_container_registry.acr: Still creating... [00m10s elapsed]
azurerm_container_registry.acr: Still creating... [00m20s elapsed]
azurerm_container_registry.acr: Creation complete after 21s
[id=.../Microsoft.ContainerRegistry/registries/petclinic11acr]
```

**Created:** `petclinic11acr` in `westeurope`
**Time taken:** 21 seconds
**What it is:** The private Docker image storage. Duru pushes all 8 service images here.
**Login server confirmed in outputs:** `petclinic11acr.azurecr.io`

ACR ran in parallel with Log Analytics and AKS because it has no dependency on them.

---

### Resource 3 — Log Analytics Workspace

```
azurerm_log_analytics_workspace.law: Creating...
azurerm_log_analytics_workspace.law: Still creating... [00m10s elapsed]
azurerm_log_analytics_workspace.law: Still creating... [00m20s elapsed]
azurerm_log_analytics_workspace.law: Still creating... [00m30s elapsed]
azurerm_log_analytics_workspace.law: Still creating... [00m40s elapsed]
azurerm_log_analytics_workspace.law: Creation complete after 46s
[id=.../Microsoft.OperationalInsights/workspaces/law-petclinic11-dev]
```

**Created:** `law-petclinic11-dev` in `westeurope`
**Time taken:** 46 seconds
**What it is:** The health log storage. AKS sends all cluster logs here for Osman to monitor in Azure Monitor.

---

### Resource 4 — AKS Cluster (Longest Step)

```
azurerm_kubernetes_cluster.aks: Creating...
azurerm_kubernetes_cluster.aks: Still creating... [00m10s elapsed]
azurerm_kubernetes_cluster.aks: Still creating... [01m00s elapsed]
azurerm_kubernetes_cluster.aks: Still creating... [02m00s elapsed]
azurerm_kubernetes_cluster.aks: Still creating... [03m00s elapsed]
azurerm_kubernetes_cluster.aks: Still creating... [04m00s elapsed]
azurerm_kubernetes_cluster.aks: Still creating... [05m00s elapsed]
azurerm_kubernetes_cluster.aks: Still creating... [06m00s elapsed]
azurerm_kubernetes_cluster.aks: Still creating... [07m00s elapsed]
azurerm_kubernetes_cluster.aks: Still creating... [07m20s elapsed]
azurerm_kubernetes_cluster.aks: Still creating... [07m30s elapsed]
azurerm_kubernetes_cluster.aks: Creation complete after 7m30s
[id=.../Microsoft.ContainerService/managedClusters/aks-petclinic11-dev]
```

**Created:** `aks-petclinic11-dev` in `westeurope`
**Time taken:** 7 minutes 30 seconds
**What it is:** The Kubernetes cluster — the cloud computer fleet that runs all 8 PetClinic microservices.

Why AKS takes so long: Azure is provisioning two virtual machines, installing the Kubernetes control plane, setting up networking, installing the monitoring agent (oms_agent connected to Log Analytics), and configuring RBAC — all automatically in the background. This is completely normal.

Cluster details confirmed from the plan output:

| Setting | Value | Meaning |
|---|---|---|
| Node count | 2 | Two virtual machines to run containers |
| VM size | Standard_B2s_v2 | Each node — 2 vCPUs and 4 GB RAM |
| Node pool name | system | The default system node pool |
| Network plugin | kubenet | Basic Kubernetes networking |
| Load balancer | standard | Standard Azure Load Balancer |
| Identity type | SystemAssigned | AKS manages its own Azure identity |
| RBAC | enabled | Role-Based Access Control is on |
| SKU tier | Free | Free control plane — suitable for dev and learning |
| OS disk type | Managed | Azure-managed SSD disks on each node |

---

### Resource 5 — AcrPull Role Assignment

```
azurerm_role_assignment.aks_acr_pull: Creating...
azurerm_role_assignment.aks_acr_pull: Still creating... [00m10s elapsed]
azurerm_role_assignment.aks_acr_pull: Still creating... [00m20s elapsed]
azurerm_role_assignment.aks_acr_pull: Creation complete after 27s
[id=.../petclinic11acr/providers/Microsoft.Authorization/roleAssignments/7451978e-d75d-7b47-7be1-d44eb5ece4c1]
```

**Created:** AcrPull permission on `petclinic11acr` granted to the AKS kubelet identity
**Time taken:** 27 seconds
**What it is:** The access badge that allows AKS to download Docker images from ACR.

Why this ran last: The role assignment needs both the ACR ID and the AKS kubelet identity to exist first. Terraform automatically detected this dependency and waited. This is one of the key benefits of Terraform — it figures out the correct order for you.

---

## Final Apply Result

```
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

acr_login_server    = "petclinic11acr.azurecr.io"
aks_name            = "aks-petclinic11-dev"
resource_group_name = "rg-petclinic11-dev"
```

**Total time:** approximately 9 minutes
**Result:** Clean — 5 added, 0 changed, 0 destroyed — exactly as planned.

---

## Complete Infrastructure — All 5 Resources Created

| Resource | Azure Name | Region | Time Taken |
|---|---|---|---|
| Resource Group | `rg-petclinic11-dev` | West Europe | 26s |
| Container Registry | `petclinic11acr` | West Europe | 21s |
| Log Analytics Workspace | `law-petclinic11-dev` | West Europe | 46s |
| AKS Cluster | `aks-petclinic11-dev` | West Europe | 7m 30s |
| AcrPull Role Assignment | On `petclinic11acr` to AKS | — | 27s |

ACR Login Server: `petclinic11acr.azurecr.io`

---

## Sub-task PETC-INF-03b — az aks get-credentials

```bash
az aks get-credentials \
  --resource-group rg-petclinic11-dev \
  --name aks-petclinic11-dev \
  --overwrite-existing
```

Output:
```
Merged "aks-petclinic11-dev" as current context in /Users/pradneelz/.kube/config
```

What this did: downloaded the cluster connection details and saved them to the local kubeconfig file. Every `kubectl` command now talks to `aks-petclinic11-dev` automatically.

Verification:
```bash
kubectl get nodes
```

Expected output — both nodes showing Ready:
```
NAME                                STATUS   ROLES   AGE   VERSION
aks-system-xxxxxxxx-vmss000000      Ready    agent   5m    v1.xx.x
aks-system-xxxxxxxx-vmss000001      Ready    agent   5m    v1.xx.x
```

Namespace created:
```bash
kubectl create namespace petclinic
# namespace/petclinic created

kubectl get namespaces
# petclinic namespace visible in the list
```

---

## Sub-task PETC-INF-03c — Team Handoff

### Duru Juliet Chinenye — Docker and ACR Engineer (PETC-103 onwards)

Your ACR login server is: `petclinic11acr.azurecr.io`

```bash
# Login to ACR before pushing any image
az acr login --name petclinic11acr

# Use this prefix for all docker tag and push commands
# petclinic11acr.azurecr.io/spring-petclinic-config-server:latest
```

### Oladayo Aremu — Kubernetes and AKS Engineer (PETC-106 onwards)

```bash
# Connect kubectl to the cluster
az aks get-credentials \
  --resource-group rg-petclinic11-dev \
  --name aks-petclinic11-dev \
  --overwrite-existing

# Verify
kubectl get nodes
# Expected: 2 nodes, STATUS = Ready

# Namespace is ready
kubectl get namespaces
# petclinic namespace is already created
```

---

## Evidence Screenshots to Capture

| Screenshot File | What to Show |
|---|---|
| `docs/terraform-evidence/terraform-apply-complete.png` | Terminal — "Apply complete! Resources: 5 added, 0 changed, 0 destroyed" |
| `docs/terraform-evidence/terraform-apply-outputs.png` | Terminal — the 3 output values printed at the bottom |
| `docs/terraform-evidence/azure-portal-resource-group.png` | Azure Portal showing `rg-petclinic11-dev` with all resources inside |
| `docs/terraform-evidence/azure-portal-acr.png` | Azure Portal — ACR `petclinic11acr` overview page |
| `docs/terraform-evidence/azure-portal-aks.png` | Azure Portal — AKS `aks-petclinic11-dev` nodes tab |
| `docs/terraform-evidence/kubectl-get-nodes.png` | Terminal — 2 nodes with STATUS = Ready |
| `docs/terraform-evidence/kubectl-namespace.png` | Terminal — `petclinic` namespace created and visible |

---

## Git Commands for This Branch

```bash
cd ~/DMI_Final_Project/spring-petclinic-devops

git add docs/terraform-evidence/
git add docs/daily-updates/pradeep-terraform-engineer.md

git commit -m "PETC-INF-03: terraform apply complete — 5 resources live, kubectl verified, team handoff done"
git push origin infra/PETC-INF-03-terraform-apply-handoff
```

PR title: `PETC-INF-03: terraform apply complete and team handoff done`
Reviewer: Benjamin Akinteye
Jira status: In Progress → Done

---

*PETC-INF-03 | Branch: infra/PETC-INF-03-terraform-apply-handoff | Terraform Engineer: Pradeep Kumar Neelaboyina | Group 9 | May 2026*
