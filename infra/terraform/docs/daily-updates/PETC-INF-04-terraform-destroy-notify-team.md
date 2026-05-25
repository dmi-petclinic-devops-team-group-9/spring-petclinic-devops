# PETC-INF-04: Terraform Destroy — Team Notify

**Branch:** `infra/PETC-INF-04-terraform-destroy-team-notify`  
**Reviewer:** Benjamin Akinteye  
**Evidence Dir:** `docs/terraform-evidence/`

---

## Quick Start

```bash
cd ~/DMI_Final_Project/spring-petclinic-devops
git checkout develop && git pull origin develop
git checkout -b infra/PETC-INF-04-terraform-destroy-team-notify
```

---

## Subtasks Checklist

| Task | Action | Evidence |
|------|--------|----------|
| 04a | Notify team 24hrs. Get sign-offs (Oladayo, Duru, Osman) | Slack confirmation |
| 04b | `kubectl get pods -A` + `kubectl get pvc -A` — verify idle | 2 screenshots |
| 04c | `cd infra/terraform && terraform destroy -auto-approve` | Terminal output screenshot |
| 04d | Azure Portal — verify resource group deleted | Portal screenshot |
| 04e | Notify team in Slack — infrastructure down | Slack message |

---

## Commands

```bash
# Verify cluster idle
kubectl get pods -A
kubectl get pvc -A

# Destroy (from infra/terraform dir)
cd infra/terraform
terraform destroy -auto-approve

# Force unlock if needed
terraform force-unlock <lock-id>

# Check git status before commit
git status
```

---

## Commit Messages

```bash
git add docs/terraform-evidence/kubectl-*.png
git commit -m "PETC-INF-04: verify cluster idle — no pods/PVCs before destroy"

git add docs/terraform-evidence/terraform-destroy-complete.png
git commit -m "PETC-INF-04: terraform destroy complete — 5 resources removed"

git add docs/terraform-evidence/azure-portal-resources-deleted.png
git commit -m "PETC-INF-04: Azure confirms rg-petclinic11-dev deleted"

git push origin infra/PETC-INF-04-terraform-destroy-team-notify
```

---

## Jira Comment Template

```
Daily update — Terraform destroy completed.

Git branch: infra/PETC-INF-04-terraform-destroy-team-notify
PR: https://github.com/petclinic-interns/spring-petclinic-devops/pull/[NUMBER]

✅ 04a: Team notified. Sign-off: Oladayo, Duru, Osman
✅ 04b: Cluster idle (no pods/PVCs)
✅ 04c: terraform destroy — "5 resources destroyed"
✅ 04d: Azure Portal confirms deletion
✅ 04e: Team notified

Blockers: None
Next: Run PETC-INF-03 (terraform apply) when ready

Status: In Progress → Done
```

---

## Expected Result

```
Destroy complete! Resources: 5 destroyed.
```

---

## Files to Save

- `docs/terraform-evidence/kubectl-get-pods-all.png`
- `docs/terraform-evidence/kubectl-get-pvc-all.png`
- `docs/terraform-evidence/terraform-destroy-complete.png`
- `docs/terraform-evidence/azure-portal-resources-deleted.png`
