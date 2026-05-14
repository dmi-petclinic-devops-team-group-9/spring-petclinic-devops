## Date: [Today's date]

### Jira Task ID
PETC-INF-05

### Chapter / Role
Terraform Engineer + Chapter 15 Database Configuration Owner

### Work Completed Today
- PETC-INF-05a: Docker Compose started with HSQLDB default — all 8 services
  confirmed running. Data reset on restart verified — screenshot attached.
- PETC-INF-05b: MySQL container started on port 3306. customers-service,
  vets-service, visits-service started with -Dspring-boot.run.profiles=mysql.
  HikariPool MySQL connection confirmed in logs. docker ps screenshot attached.
- PETC-INF-05c: Owner "MySQL Persistence" added via UI. customers-service
  restarted. Owner record confirmed still present — persistence verified.
  Before/after screenshots attached to Jira.
- PETC-INF-05d: Chapter 15 documentation reviewed and confirmed accurate.
  Evidence committed to docs/db-evidence/.

### Files Updated
- docs/db-evidence/hsqldb-default-running.png
- docs/db-evidence/hsqldb-data-reset-proof.png
- docs/db-evidence/mysql-profile-running.png
- docs/db-evidence/mysql-owner-before-restart.png
- docs/db-evidence/mysql-persistence-verified.png
- docs/daily-updates/pradeep-terraform-engineer.md

### Issues / Blockers
None.

### Next Plan
- Raise PR for PETC-INF-05 — reviewer: Benjamin Akinteye
- Update Jira ticket PETC-INF-05 status: In Progress → Review
