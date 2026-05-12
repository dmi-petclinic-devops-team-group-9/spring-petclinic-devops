# PETC-INF-05 — Full Implementation Guide

**Ticket:** PETC-INF-05  
**Story:** Document and demonstrate Chapter 15 — Database Configuration (HSQLDB and MySQL)  
**Assigned to:** Pradeep Kumar Neelaboyina  
**Epic:** PETC-INF (Infrastructure Epic)  
**Reviewer (PR):** Benjamin Akinteye  
**Branch:** `infra/PETC-INF-05-db-config-documentation`  

---

## Before You Start — Prerequisites Check

Run these in your terminal. All must succeed before doing anything else:

```bash
# Verify everything you need is installed
java -version          # Must show Java 17
docker --version       # Must show Docker running
docker compose version # Must work (not just docker-compose)
git --version

# Verify Docker Desktop is actually running
docker ps              # If this errors, open Docker Desktop and wait for it to start

# Verify Docker images are available
docker images | grep petclinic
# You should see 8 springcommunity/spring-petclinic-* images listed
```

Also make sure you are in the project root:

```bash
cd ~/DMI_Final_Project/spring-petclinic-microservices
ls    # You should see docker-compose.yml listed
```

---

## Sub-Task Overview

| Sub-task | What it covers | Evidence file |
|---|---|---|
| PETC-INF-05a | Verify HSQLDB default mode via Docker Compose | `hsqldb-default-running.png` + `hsqldb-data-reset-proof.png` |
| PETC-INF-05b | Demonstrate MySQL profile switching | `mysql-profile-running.png` |
| PETC-INF-05c | Verify data persistence with MySQL | `mysql-owner-before-restart.png` + `mysql-persistence-verified.png` |
| PETC-INF-05d | Update and verify Chapter 15 documentation | `pradeep-terraform-engineer.md` |
| PETC-INF-05e | Commit evidence and raise PR | GitHub PR + Jira comment |

---

## PETC-INF-05a — Verify HSQLDB Default Mode

**What this is:** Docker Compose starts all 8 services using HSQLDB by default — no database setup needed. Your job is to prove this works and prove data resets on restart.

**Why HSQLDB?** It is an embedded in-memory database. Spring Boot loads it automatically when no external database is configured. Zero setup — but all data is lost when the container or service stops.

### Step 1 — Create the evidence folder

```bash
# From the project root
mkdir -p docs/db-evidence
```

### Step 2 — Start everything with Docker Compose

> **Note:** If Docker Desktop is not running, open it first and wait for the whale icon in the menu bar to be completely still before proceeding.

```bash
docker compose up
```

The three API key warnings below are **expected and harmless** — they relate to the genai-service only:

```
WARN: "OPENAI_API_KEY" variable is not set. Defaulting to a blank string.
WARN: "AZURE_OPENAI_KEY" variable is not set. Defaulting to a blank string.
WARN: "AZURE_OPENAI_ENDPOINT" variable is not set. Defaulting to a blank string.
```

Wait 2–3 minutes. You will know it is ready when the log output slows down and you see lines like:

```
customers-service  | Started CustomersServiceApplication in X.XXX seconds
api-gateway        | Started ApiGatewayApplication in X.XXX seconds
```

### Step 3 — Verify all containers are up

Open a **second terminal** and run:

```bash
docker compose ps
```

You should see all 8 containers with **STATUS: running**. **Take a screenshot** — save as `docs/db-evidence/hsqldb-default-running.png`.

Then open your browser at `http://localhost:8080` — the PetClinic UI should load showing the default owners list (George Franklin, Betty Davis, Eduardo Rodriquez etc.).

### Step 4 — Confirm HSQLDB is active in the logs

```bash
docker compose logs customers-service | grep -i "hsqldb\|hikari\|jdbc"
```

Look for a line containing:

```
jdbc:hsqldb:mem
```

That `hsqldb:mem` confirms in-memory database is active, not MySQL.

### Step 5 — Prove data resets on restart

```bash
# In the browser:
# Go to http://localhost:8080
# Click "Find Owners" → "Add Owner"
# Fill in:
#   First Name:  Test
#   Last Name:   HSQLDB
#   Address:     1 Test Street
#   City:        London
#   Telephone:   01234567890
# Click "Add Owner" — confirm the new owner appears in the list

# Now stop Docker Compose
# Press Ctrl+C in the docker compose terminal, then:
docker compose down

# Restart
docker compose up

# Go back to browser → Find Owners → search for "HSQLDB"
# The owner you added is GONE — this proves HSQLDB resets on restart
```

**Take a screenshot** of the empty search result after restart — save as `docs/db-evidence/hsqldb-data-reset-proof.png`.

### Step 6 — Stop Docker Compose before moving on

```bash
# Press Ctrl+C in the docker compose terminal, then:
docker compose down
```

---

## PETC-INF-05b — Demonstrate MySQL Profile Switching

**What this is:** You start a real MySQL database container, then start only the 3 data services with the `mysql` Spring profile instead of the default.

**Why only 3 services?** Only `customers-service`, `vets-service`, and `visits-service` store domain data. The others (config-server, discovery-server, api-gateway, admin-server) are routing and infrastructure services with no persistent domain data of their own.

### Step 1 — Start config-server first (mandatory)

Open **Terminal 1**:

```bash
cd ~/DMI_Final_Project/spring-petclinic-microservices/spring-petclinic-config-server
../mvnw spring-boot:run
```

Wait until you see:

```
Started ConfigServerApplication in X.XXX seconds
```

### Step 2 — Start discovery-server second (mandatory)

Open **Terminal 2**:

```bash
cd ~/DMI_Final_Project/spring-petclinic-microservices/spring-petclinic-discovery-server
../mvnw spring-boot:run
```

Wait until you see `Started EurekaServiceApplication`, then open `http://localhost:8761` to confirm the Eureka dashboard is up.

### Step 3 — Start the MySQL container

Open **Terminal 3**:

```bash
docker run \
  --name petclinic-mysql \
  -e MYSQL_ROOT_PASSWORD=petclinic \
  -e MYSQL_DATABASE=petclinic \
  -p 3306:3306 \
  mysql:8.4.5
```

Wait until you see this line — it means MySQL is fully ready:

```
/usr/sbin/mysqld: ready for connections. Version: '8.4.5'
```

> **Important:** Do not proceed to Step 4 until MySQL prints this exact message.

### Step 4 — Start the 3 data services with the MySQL profile

Open **Terminal 4** — customers-service:

```bash
cd ~/DMI_Final_Project/spring-petclinic-microservices/spring-petclinic-customers-service
../mvnw spring-boot:run -Dspring-boot.run.profiles=mysql
```

Watch the logs — look for this line which confirms MySQL connection (not HSQLDB):

```
HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl
```

Open **Terminal 5** — vets-service:

```bash
cd ~/DMI_Final_Project/spring-petclinic-microservices/spring-petclinic-vets-service
../mvnw spring-boot:run -Dspring-boot.run.profiles=mysql
```

Open **Terminal 6** — visits-service:

```bash
cd ~/DMI_Final_Project/spring-petclinic-microservices/spring-petclinic-visits-service
../mvnw spring-boot:run -Dspring-boot.run.profiles=mysql
```

### Step 5 — Take the screenshot

Open a new terminal and run:

```bash
docker ps
```

You should see the `petclinic-mysql` container with STATUS `Up`. **Take a screenshot** of `docker ps` showing the MySQL container — save as `docs/db-evidence/mysql-profile-running.png`.

Also screenshot Terminal 4 showing the `HikariPool` MySQL connection line — this is key proof the `mysql` profile is active.

### If you see a connection refused error

```bash
# If customers-service says "Connection refused" or "Communications link failure"
# MySQL is not ready yet — check Terminal 3 for "ready for connections" message.
# Wait 30 more seconds then try starting the service again.
```

---

## PETC-INF-05c — Verify Data Persistence with MySQL

**What this is:** The critical proof that MySQL is different from HSQLDB — data survives a service restart.

All terminals from PETC-INF-05b should still be running. Proceed:

### Step 1 — Start api-gateway to access the UI

Open **Terminal 7**:

```bash
cd ~/DMI_Final_Project/spring-petclinic-microservices/spring-petclinic-api-gateway
../mvnw spring-boot:run
```

Wait for it to start, then open `http://localhost:8080`.

### Step 2 — Add a test owner

Click **"Find Owners"** → **"Add Owner"** and fill in:

```
First Name:  MySQL
Last Name:   Persistence
Address:     99 Test Road
City:        Dublin
Telephone:   07700900123
```

Click **"Add Owner"** — confirm the owner appears in the list.

**Take a screenshot of the owner in the UI** — save as `docs/db-evidence/mysql-owner-before-restart.png`.

### Step 3 — Stop customers-service only

Go to **Terminal 4** (customers-service) and press `Ctrl+C`. Wait for the service to fully shut down.

### Step 4 — Restart customers-service with MySQL profile

In the same **Terminal 4**:

```bash
../mvnw spring-boot:run -Dspring-boot.run.profiles=mysql
```

Wait for it to fully start (look for `Started CustomersServiceApplication`).

### Step 5 — Verify the data is still there

Go back to `http://localhost:8080` → Click **"Find Owners"** → search for `MySQL`.

The owner **MySQL Persistence** should still appear — the data survived the restart.

**Take a screenshot of the owner still present after restart** — save as `docs/db-evidence/mysql-persistence-verified.png`.

### Step 6 — Add this comparison as a Jira comment

```
HSQLDB: Test owner added in PETC-INF-05a was gone after docker compose restart.
MySQL:  Owner "MySQL Persistence" survived customers-service restart because
        data is stored in the petclinic-mysql Docker container, not in memory.
```

---

## PETC-INF-05d — Update Chapter 15 Documentation

**What this is:** Verify Chapter 15 in the project guide is accurate against what you just ran, update your daily log file.

### Step 1 — Stop all running services cleanly

```bash
# Press Ctrl+C in each terminal (Terminals 3 through 7)

# Then stop and remove the MySQL container
docker stop petclinic-mysql
docker rm petclinic-mysql
```

### Step 2 — Update your daily log file

```bash
# Open in VS Code
code docs/daily-updates/pradeep-terraform-engineer.md
```

Add today's entry:

```markdown
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
```

Save and close the file.

---

## PETC-INF-05e — Commit Evidence and Raise PR

Run all of the following in order from the project root.

### Step 1 — Confirm you are on the correct branch

```bash
git status
# Should show: On branch infra/PETC-INF-05-db-config-documentation
```

If not already on it:

```bash
git checkout develop
git pull origin develop
git checkout -b infra/PETC-INF-05-db-config-documentation
```

### Step 2 — Stage the architecture diagram (if not already staged)

```bash
# The A prefix in git output means it's already staged — skip this if already staged
git add SPCM_Project_Architecture.png
```

### Step 3 — Stage all evidence files

```bash
git add docs/db-evidence/hsqldb-default-running.png
git add docs/db-evidence/hsqldb-data-reset-proof.png
git add docs/db-evidence/mysql-profile-running.png
git add docs/db-evidence/mysql-owner-before-restart.png
git add docs/db-evidence/mysql-persistence-verified.png
git add docs/daily-updates/pradeep-terraform-engineer.md
```

### Step 4 — Commit in logical batches

```bash
# Commit 1 — architecture diagram (separate, clean commit)
git commit -m "PETC-INF-05: add project architecture diagram — SPCM overview"

# Commit 2 — DB evidence screenshots
git commit -m "PETC-INF-05: add DB config evidence — HSQLDB default and MySQL profile verified"

# Commit 3 — daily log update
git commit -m "PETC-INF-05: update daily log — DB config sub-tasks 05a through 05d complete"
```

### Step 5 — Push the branch

```bash
git push origin infra/PETC-INF-05-db-config-documentation
```

### Step 6 — Open a Pull Request on GitHub

1. Go to your GitHub repo in the browser
2. You will see a yellow banner: **"infra/PETC-INF-05-db-config-documentation had recent pushes"** → click **"Compare & pull request"**
3. Set the following:
   - **Base branch:** `develop`
   - **Title:** `PETC-INF-05: Database configuration evidence and Chapter 15 verification`
   - **Reviewer:** Benjamin Akinteye

### Step 7 — Paste this comment into Jira ticket PETC-INF-05

```
Daily update — PETC-INF-05 complete.

Git branch: infra/PETC-INF-05-db-config-documentation
Pull Request: https://github.com/petclinic-interns/spring-petclinic-devops/pull/[NUMBER]

Work completed:
- PETC-INF-05a: Docker Compose started successfully with HSQLDB default.
  All 8 services confirmed running. Test owner added, service restarted,
  data confirmed reset — proving HSQLDB is in-memory only.
- PETC-INF-05b: MySQL container started (mysql:8.4.5, port 3306).
  customers-service, vets-service, visits-service started with
  -Dspring-boot.run.profiles=mysql. HikariPool MySQL connection confirmed
  in service logs. docker ps screenshot attached.
- PETC-INF-05c: Owner "MySQL Persistence" added via PetClinic UI.
  customers-service stopped and restarted with mysql profile.
  Owner record confirmed present after restart — persistence verified.
  Before and after screenshots attached.
- PETC-INF-05d: Chapter 15 reviewed and confirmed accurate.
  All commands tested against real running environment.

Files committed:
- SPCM_Project_Architecture.png
- docs/db-evidence/hsqldb-default-running.png
- docs/db-evidence/hsqldb-data-reset-proof.png
- docs/db-evidence/mysql-profile-running.png
- docs/db-evidence/mysql-owner-before-restart.png
- docs/db-evidence/mysql-persistence-verified.png
- docs/daily-updates/pradeep-terraform-engineer.md

Blockers: None
Next: Awaiting PR review from Benjamin → merge to develop → Done

Status: In Progress → Review
```

### Step 8 — Move the Jira ticket

In Jira, drag **PETC-INF-05** from **In Progress** → **Review**.

---

## Troubleshooting Reference

| Problem | Likely cause | Fix |
|---|---|---|
| `docker ps` — Cannot connect to Docker daemon | Docker Desktop not running | Open Docker Desktop, wait for whale icon to be still |
| `docker compose ps` shows empty table | Docker images not built or Docker not running | Run `docker images \| grep petclinic` to check images exist, ensure Docker is running |
| `Connection refused` when starting MySQL profile service | MySQL container not ready yet | Wait 60 seconds — look for `ready for connections` in MySQL terminal |
| Spring service crashes immediately | config-server not started yet | Start config-server first, wait for it to fully start, then try again |
| `HikariPool` shows `hsqldb` not MySQL | Profile flag missing or incorrect | Confirm you typed exactly `-Dspring-boot.run.profiles=mysql` with no spaces |
| `./mvnw: Permission denied` | Execute permission missing | Run `chmod +x mvnw` then try again |
| Port 3306 already in use | Another MySQL process running | Run `docker stop petclinic-mysql && docker rm petclinic-mysql` then restart |
| Docker build fails with ACR 401 Unauthorized | Not logged into ACR | Run `az acr login --name petclinic11acr` then retry — or use `mvnw spring-boot:run` approach instead |

---

## Evidence Files Checklist

| File | Sub-task | What it shows |
|---|---|---|
| `docs/db-evidence/hsqldb-default-running.png` | 05a | `docker compose ps` — all 8 containers Up + browser showing PetClinic UI |
| `docs/db-evidence/hsqldb-data-reset-proof.png` | 05a | Empty search result after restart — proves data was lost |
| `docs/db-evidence/mysql-profile-running.png` | 05b | `docker ps` showing `petclinic-mysql` container running |
| `docs/db-evidence/mysql-owner-before-restart.png` | 05c | Owner "MySQL Persistence" visible in UI before restart |
| `docs/db-evidence/mysql-persistence-verified.png` | 05c | Same owner still visible after customers-service restart |

---

*PETC-INF-05 — Spring PetClinic Microservices | Group 9 | Pradeep Kumar Neelaboyina | May 2026*
