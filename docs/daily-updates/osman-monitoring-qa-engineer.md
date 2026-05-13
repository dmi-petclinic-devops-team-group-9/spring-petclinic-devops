## Date: 07-May-2026

### Jira Task IDs
PETC-107, PETC-207, PETC-307, PETC-407, PETC-507, PETC-607, PETC-707, PETC-807

### Chapter / Role
Chapter 11 — Monitoring, QA Testing, and Final Demo Engineer

### Work Completed Today
- Created all 8 monitoring and QA Jira tickets in the DMI Internship Project backlog
- Added full descriptions to all 8 tickets
- Added subtasks to all 8 tickets (PETC-107a through PETC-807e)
- Assigned all tickets to myself (Osman Ali Farah)
- Linked all tickets to their correct epics (PETC-E1 through PETC-E8)
- SCRUM-135 (PETC-107) was added to SCRUM Sprint 1 by Pradeep

### Jira Tickets Created
- SCRUM-135: PETC-107 — Monitor config-server (Epic: PETC-E1)
- SCRUM-141: PETC-207 — Monitor discovery-server (Epic: PETC-E2)
- SCRUM-146: PETC-307 — Monitor api-gateway + end-to-end QA (Epic: PETC-E3)
- SCRUM-151: PETC-407 — Monitor customers-service + QA CRUD (Epic: PETC-E4)
- SCRUM-162: PETC-507 — Monitor vets-service (Epic: PETC-E5)
- SCRUM-171: PETC-607 — Monitor visits-service + QA circuit breaker (Epic: PETC-E6)
- SCRUM-176: PETC-707 — Monitor genai-service (Epic: PETC-E7)
- SCRUM-180: PETC-807 — Full monitoring stack + Azure Monitor alerts (Epic: PETC-E8)

### Files Updated
- docs/daily-updates/osman-monitoring-qa-engineer.md

### Blockers
- Cannot execute monitoring tasks yet
- Waiting for Pradeep to complete Terraform (AKS + ACR provisioning)
- Waiting for Duru to push Docker images to ACR
- Waiting for Oladayo to deploy all 8 services to AKS

### Next Plan
- Monitor services in Spring Boot Admin once AKS deployment is ready
- Verify Prometheus targets for all 8 services
- Run JMeter load test and verify Grafana counters
- Check Zipkin traces for full request chain
- Set up Azure Monitor alert for CrashLoopBackOff

---

## Date: 12-May-2026

### Jira Task ID
SCRUM-135 (PETC-107), SCRUM-141 (PETC-207)

### Chapter / Role
Chapter 11 — Monitoring & QA Engineer

### Work Completed Today
- Connected to AKS cluster aks-petclinic11-dev
- Verified 2 nodes — both in Ready state
- Verified all 8 pods Running 1/1 in petclinic namespace
- Port-forwarded Spring Boot Admin — config-server and discovery-server confirmed UP
- Verified Azure Monitor (AMA metrics) running in kube-system
- Captured live CPU/Memory metrics for all 8 pods via kubectl top
- Confirmed Zipkin, Prometheus and Grafana are not deployed — raised with Yinusa 
- Updated SCRUM-135 and SCRUM-141 subtasks in Jira with comments and screenshots
- Moved SCRUM-141 to Sprint 2

### Blockers
- Prometheus not deployed — PETC-107b, PETC-207b blocked
- Zipkin not deployed — PETC-107c, PETC-207c blocked
- PETC-107d, 107e, 207c, 207d pending Ikedimma approval

### Next Plan
- Continue SCRUM-146 (PETC-307) — Monitor api-gateway + end-to-end QA
- Deploy Prometheus, Grafana, Zipkin once Yinusa action

---

## Date: 13-May-2026

### Jira Task ID
SCRUM-146 (PETC-307)

### Chapter / Role
Chapter 11 — Monitoring & QA Engineer

### Work Completed Today
- Moved SCRUM-146 to Sprint 2
- api-gateway confirmed UP in Spring Boot Admin
- Partially completed QA checklist — PetClinic app accessible at http://20.31.145.111
- Owners list, Owner detail page and Vet list verified
- Updated all 4 subtasks in Jira with comments and screenshots

### Blockers
- Prometheus/Grafana not deployed — PETC-307b blocked
- Zipkin not deployed — PETC-307c blocked
- Full QA checklist pending domain name from Oladayo

### Next Plan
- Continue SCRUM-151 (PETC-407) — Monitor customers-service + QA CRUD
