# Prometheus + Grafana Monitoring Setup

## What gets monitored and where metrics come from

```
Your Browser
     │
     ├── http://localhost        → Employee App (Frontend)
     ├── http://localhost:8080   → Spring Boot API
     ├── http://localhost:9090   → Prometheus UI
     ├── http://localhost:3000   → Grafana Dashboards
     └── http://localhost:8081   → cAdvisor (raw container metrics)


Metric Collection Flow:
────────────────────────
Spring Boot ──/actuator/prometheus──► Prometheus ──► Grafana
MySQL       ──mysql-exporter:9104──► Prometheus ──► Grafana
Docker      ──cadvisor:8080────────► Prometheus ──► Grafana
```

## Metrics you will see in Grafana

| Metric | Source | Grafana Panel |
|---|---|---|
| Response Time (P50/P95/P99) | Spring Boot Actuator | Response Time panel |
| Throughput (requests/sec) | Spring Boot Actuator | HTTP Request Rate panel |
| Error Rate (4xx, 5xx) | Spring Boot Actuator | HTTP Errors panel |
| JVM Heap Memory | Spring Boot Actuator | JVM Memory Usage panel |
| DB Connection Pool | HikariCP via Actuator | Database Connection Pool panel |
| Container CPU % | cAdvisor | Container CPU Usage panel |
| Container Memory | cAdvisor | Container Memory Usage panel |
| Network I/O | cAdvisor | Network I/O panel |
| MySQL Queries/sec | mysql-exporter | MySQL Queries panel |
| MySQL Connections | mysql-exporter | MySQL Connections panel |

---

## Step 1 — Copy files into your project

Copy these files into your employee-docker-project folder:

1. docker-compose.yml          → replace existing one (project root)
2. pom.xml                     → replace backend/pom.xml
3. application.properties      → replace backend/src/main/resources/application.properties
4. monitoring/ folder          → place in project root

Final structure:
employee-docker-project/
├── docker-compose.yml          ← updated (monitoring services added)
├── backend/
│   ├── pom.xml                 ← updated (micrometer-registry-prometheus added)
│   └── src/main/resources/
│       └── application.properties  ← updated (prometheus endpoint exposed)
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml
│   └── grafana/
│       └── provisioning/
│           ├── datasources/
│           │   └── prometheus.yml
│           └── dashboards/
│               ├── dashboard.yml
│               └── employee-app.json

---

## Step 2 — Rebuild backend (pom.xml changed)

cd employee-docker-project
docker compose build backend

---

## Step 3 — Start everything

docker compose up -d

---

## Step 4 — Verify all services are up

docker compose ps

Expected output:
NAME                       STATUS
employee-mysql             Up (healthy)
employee-backend           Up (healthy)
employee-frontend          Up (healthy)
employee-prometheus        Up
employee-grafana           Up
employee-mysql-exporter    Up
employee-cadvisor          Up

---

## Step 5 — Verify Prometheus is scraping

Open: http://localhost:9090/targets

You should see:
spring-boot-backend    UP    ← Spring Boot metrics
mysql                  UP    ← MySQL metrics
cadvisor               UP    ← Container metrics
prometheus             UP    ← Self monitoring

If any show DOWN — check docker logs for that exporter.

---

## Step 6 — Open Grafana

URL:      http://localhost:3000
Username: admin
Password: admin123

Dashboard is auto-loaded: "Employee App - Full Stack Monitoring"

---

## Step 7 — Generate some traffic to see metrics

Open a second Git Bash window and run:

for i in $(seq 1 100); do
  curl -s http://localhost:8080/api/employees > /dev/null
  curl -s http://localhost:8080/api/employees/1 > /dev/null
  sleep 0.5
done

Watch the Grafana charts update in real time!

---

## Verify Prometheus endpoint on Spring Boot

curl http://localhost:8080/actuator/prometheus

You should see hundreds of lines like:
# HELP http_server_requests_seconds
# TYPE http_server_requests_seconds histogram
http_server_requests_seconds_bucket{...} 5
jvm_memory_used_bytes{area="heap",...} 157286400
hikaricp_connections_active{...} 1

---

## Key Prometheus queries (practice in Prometheus UI)

# Requests per second
sum(rate(http_server_requests_seconds_count[1m]))

# Average response time in ms
sum(rate(http_server_requests_seconds_sum[1m])) /
sum(rate(http_server_requests_seconds_count[1m])) * 1000

# P95 response time
histogram_quantile(0.95,
  sum(rate(http_server_requests_seconds_bucket[5m])) by (le))

# Error rate %
sum(rate(http_server_requests_seconds_count{status=~"5.."}[1m])) /
sum(rate(http_server_requests_seconds_count[1m])) * 100

# Active DB connections
hikaricp_connections_active

# JVM heap used
jvm_memory_used_bytes{area="heap"}
