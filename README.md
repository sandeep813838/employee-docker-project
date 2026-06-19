# Employee Management System — Docker 3-Tier Architecture

A hands-on Docker learning project for Linux/DevOps interview preparation.
Built to practice every Docker concept asked in DevOps interviews.

## Architecture

```
Browser → http://localhost
              │
         ┌────▼────┐
         │  Nginx  │  Port 80   (Frontend — static HTML)
         └────┬────┘
              │ proxy /api/*
         ┌────▼──────────┐
         │  Spring Boot  │  Port 8080  (REST API)
         └────┬──────────┘
              │ JDBC
         ┌────▼────┐
         │  MySQL  │  Port 3306  (Database)
         └────┬────┘
              │
         Named Volume
         employee_mysql-data
```

## Docker Concepts Covered

- Docker Images, Containers, Dockerfile
- CMD vs ENTRYPOINT
- Multi-stage Build (Maven → JRE only)
- Docker Compose (3 services, 1 command)
- Custom Bridge Network + Docker DNS
- Named Volumes (data persistence)
- Environment Variables
- Health Checks (all 3 services)
- Restart Policies (unless-stopped)
- Resource Limits (memory + cpu)
- Container Security (non-root USER)
- docker stats, docker logs, docker inspect, docker exec
- 20 Troubleshooting Scenarios

## Prerequisites (Windows 10)

1. Install Docker Desktop: https://www.docker.com/products/docker-desktop/
2. Enable WSL 2 backend (Docker Desktop will prompt)
3. Allocate resources in Docker Desktop Settings → Resources:
   - CPUs: 4
   - Memory: 4 GB

## Quick Start

```bash
# Clone / open the project folder
cd employee-docker-project

# Build and start all 3 services
docker compose up -d

# Watch startup (takes ~2 min for first build)
docker compose logs -f

# Open browser
http://localhost        → Frontend UI
http://localhost:8080/api/employees  → API directly
http://localhost:8080/actuator/health → Health check
```

## Key Commands

```bash
# Start
docker compose up -d

# Stop (keep data)
docker compose down

# Stop + delete volumes (DATA LOSS)
docker compose down -v

# View logs
docker compose logs -f
docker logs -f employee-backend

# Shell into backend
docker exec -it employee-backend sh

# Monitor resources
docker stats

# Inspect container
docker inspect employee-backend

# Check health
docker ps
```

## Folder Structure

```
employee-docker-project/
├── docker-compose.yml       ← orchestrates all 3 services
├── README.md
├── frontend/
│   ├── Dockerfile           ← nginx, serves index.html
│   ├── nginx.conf           ← proxies /api/* to backend
│   └── index.html           ← full CRUD UI
├── backend/
│   ├── Dockerfile           ← multi-stage Maven → JRE
│   ├── pom.xml
│   └── src/                 ← Spring Boot REST API
├── mysql/
│   └── init.sql             ← schema + seed data
└── interview-notes/
    ├── TROUBLESHOOTING_LAB.md   ← 20 break-and-fix scenarios
    └── INTERVIEW_QA.md          ← Q&A for common interview questions
```

## Resume Line

Built and deployed a Dockerized 3-tier Employee Management System using
Spring Boot, MySQL, Nginx, Docker Compose, multi-stage builds, named volumes,
custom bridge networks, health checks, and non-root containers.
Practiced 20 real-world troubleshooting scenarios including OOM kills,
CMD/ENTRYPOINT failures, networking issues, and persistent storage management.
