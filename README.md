# Employee Management System — DevOps Project

A production-style 3-tier application built to practice and demonstrate end-to-end DevOps skills.
The same application is deployed across multiple platforms, each adding a new layer of real-world DevOps practice.

## Application Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Nginx (static HTML/JS, reverse proxy) |
| Backend | Spring Boot 3 / Java 17 REST API |
| Database | MySQL 8.0 |

## DevOps Stack Implemented

| Tool | What Was Done |
|------|--------------|
| Docker | Multi-stage Dockerfile (800MB → 250MB), non-root user, health checks |
| Docker Compose | 3-tier orchestration, custom bridge network, named volumes, health check dependencies |
| Jenkins | 8-stage declarative CI/CD pipeline: checkout → build → test → tag → push → deploy → smoke test → cleanup |
| Prometheus + Grafana | Full observability — app metrics, MySQL exporter, cAdvisor, JVM metrics |
| Kubernetes (Minikube) | StatefulSet, Deployments, Services (ClusterIP/NodePort/Headless), ConfigMaps, Secrets, Ingress, RBAC, HPA |
| Helm | Full chart with values.yaml and environment-specific override files |

## Project Structure

```
├── app/
│   ├── backend/          # Spring Boot application + Dockerfile
│   └── frontend/         # Nginx + index.html + Dockerfile
├── docker-compose.yml    # Local full-stack deployment
├── docker-compose-jenkins.yml
├── Jenkinsfile           # CI/CD pipeline definition
├── k8s/                  # Plain Kubernetes YAML manifests
├── helm/employee-chart/  # Helm chart (templated version of k8s/)
└── rbac/                 # RBAC ServiceAccounts, Roles, Bindings
```

## Quick Start

### Run with Docker Compose
```bash
docker compose up -d
# Access at http://localhost
```

### Deploy to Kubernetes (Minikube)
```bash
minikube start --driver=docker --cpus=2 --memory=3500
minikube image load employee-backend:1.0
minikube image load employee-frontend:1.0

# Option 1: Plain YAML
kubectl apply -f k8s/

# Option 2: Helm
helm install employee-app helm/employee-chart

# Access
minikube tunnel   # keep running in separate terminal
# Open: http://employee.local
```

## Key Technical Decisions

**Multi-stage Docker build** — Stage 1 uses Maven+JDK to compile; Stage 2 starts fresh with JRE-only Alpine. Result: 250MB instead of 800MB.

**StatefulSet for MySQL, Deployment for backend/frontend** — MySQL needs stable pod identity and dedicated persistent storage (PVC follows pod across restarts). Backend and frontend are stateless — any replica can serve any request.

**Headless Service for MySQL** — Standard ClusterIP load-balances across pods. Headless (clusterIP: None) lets StatefulSet pods be addressed individually (mysql-0, mysql-1...) — required for databases.

**ConfigMap file-mount for Nginx config** — nginx.conf injected at deploy time via ConfigMap + subPath mount instead of baked into the image. Config changes don't require image rebuilds.

**initContainers instead of depends_on** — Kubernetes has no native equivalent to Docker Compose's `depends_on: condition: service_healthy`. An initContainer looping `nc -z mysql 3306` blocks the main container from starting until MySQL is reachable.

**RBAC least-privilege** — Each pod runs as a dedicated ServiceAccount (mysql-sa, backend-sa) with a Role granting only the specific verbs actually needed. Verified with `kubectl auth can-i`.

## Real Bugs Hit and Fixed

| Bug | Platform | Root Cause | Fix |
|-----|----------|-----------|-----|
| MySQL OOM kill mid-init (Exit 137) | Kubernetes | No memory limit set; init needs more RAM than steady-state | Raised limits.memory, wiped PVC for clean re-init |
| Backend killed by liveness probe (Exit 143) | Kubernetes | Probe fired before slow JVM startup completed on 4-core hardware | Raised initialDelaySeconds to 180s based on observed startup time |
| ImagePullBackOff after minikube delete | Kubernetes | Minikube image cache is separate from Docker Desktop and not persistent | Re-run minikube image load after every cluster recreation |
| Frontend "Cannot reach backend" | Kubernetes | localhost:8080 hardcoded in index.html — worked in Compose by coincidence, broke in K8s | Switched to relative path /api/employees |
| Ingress addon timeout | Kubernetes | Resource-stressed node (104MB free), images pulled during timeout window | Pre-pull images via minikube ssh, reduce mysql memory limit post-init |
| Jenkins smoke test hit wrong port | Docker/Jenkins | Jenkins curled its own Jetty (port 8080) instead of the app | Joined Jenkins to app network, curled by service name |

## Author

Srinivas Kumar — Linux/Unix Administrator transitioning to DevOps Engineer.
10+ years infrastructure experience. Hands-on DevOps skills built through this project.
