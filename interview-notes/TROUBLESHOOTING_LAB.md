# Docker Troubleshooting Lab — 20 Scenarios

Practice each scenario: Break it → Observe the error → Fix it.

---

## S1 — Wrong CMD (Container exits immediately)
Break: Change CMD to ["wrong-file.jar"] in backend Dockerfile. Rebuild.
Observe: docker logs employee-backend → "Unable to access jarfile wrong-file.jar"
         docker ps -a → Exited (1)
Fix: Restore CMD ["employee-api.jar"]

---

## S2 — Wrong ENTRYPOINT (Exit Code 127)
Break: Change ENTRYPOINT to ["javaXXX","-jar"]
Observe: Exited (127) — 127 means command not found
Fix: Restore ENTRYPOINT ["java","-jar"]

---

## S3 — Wrong DB Hostname
Break: Set DB_HOST: wronghost in docker-compose.yml
Observe: docker logs employee-backend → "Communications link failure — wronghost:3306"
Fix: Restore DB_HOST: mysql
Why: Docker DNS resolves service names. "mysql" → container IP automatically.

What is happening inside
When you set DB_HOST: wronghost, this is the chain of events:
docker compose up -d backend
        │
        ▼
Spring Boot starts
        │
        ▼
Reads environment variable → DB_HOST=wronghost
        │
        ▼
Tries to connect → jdbc:mysql://wronghost:3306/employees
        │
        ▼
Docker DNS lookup → "wronghost" → NOT FOUND ❌
        │
        ▼
Spring Boot crashes / keeps retrying
        │
        ▼
Health check runs → wget http://localhost:8080/actuator/health
        │
        ▼
No response (app never started properly)
        │
        ▼
Health check FAILS 3 times → Docker marks → (unhealthy)
---

## S4 — Wrong DB Password
Break: Set DB_PASSWORD: wrongpassword
Observe: "Access denied for user root (using password: YES)"
Fix: Restore DB_PASSWORD: password

---

## S5 — Wrong Port Mapping
Break: Change to "9999:8080"
Observe: localhost:8080 → connection refused. localhost:9999 → works.
Fix: Restore "8080:8080"
Rule: Left = host port, Right = container port.

---

## S6 — Volume Persistence Test
Steps:
  1. Add employee via UI
  2. docker compose stop mysql && docker compose rm mysql
  3. docker compose up -d mysql
  4. Data is still there!
Lesson: Named volumes survive container deletion.

---

## S7 — Volume Deletion (Data Loss)
Run: docker compose down -v
Lesson: -v flag removes volumes. NEVER run on prod without backup.

---

## S8 — OOM Kill (Exit Code 137)
Run: docker run --memory=100m --name oom-test --network employee-net employee-backend:1.0
Observe: Exited (137) — 137 = kernel OOM kill
Fix: Increase memory limit or tune JVM heap with -Xmx256m

---

## S9 — Security Check
Run: docker exec employee-backend whoami → appuser (non-root, correct)
     docker run --rm nginx whoami → root (bad practice)
Interview answer: Root in container = full host access if compromised.

---

## S10 — Restart Policy Demo
Run: docker exec employee-backend kill 1
Watch: docker ps → container automatically restarts (restart: unless-stopped)

---

## S11 — docker stats
docker stats                    # all containers live
docker stats --no-stream        # one-time snapshot
docker stats employee-backend   # specific container
Look for: MEM USAGE near MEM LIMIT = OOM risk

---

## S12 — docker inspect
docker inspect employee-backend
docker inspect -f '{{.NetworkSettings.Networks.employee-net.IPAddress}}' employee-backend
docker inspect -f '{{.State.Health.Status}}' employee-backend

---

## S13 — docker exec Exploration
docker exec -it employee-backend sh
  ps -ef          # processes
  env             # environment variables
  ls -la /app    # filesystem
  whoami          # user
  hostname        # container ID

---

## S14 — docker logs Patterns
docker logs employee-backend             # all logs
docker logs -f employee-backend          # follow
docker logs --tail 50 employee-backend   # last 50 lines
docker logs -t employee-backend          # with timestamps
docker logs --since 10m employee-backend # last 10 minutes

---

## S15 — Network DNS
docker network ls
docker network inspect employee-net
docker exec employee-backend ping mysql     # resolves via Docker DNS
docker exec employee-backend ping frontend

---

## S16 — Multi-Stage Size Comparison
Multi-stage image: ~250MB (JRE only)
Single-stage fat:  ~800MB+ (Maven + JDK + source)
Interview: Multi-stage = smaller attack surface, faster deploys, less storage.

---

## S17 — Health Check States
watch 'docker ps --format "table {{.Names}}\t{{.Status}}"'
States: starting → healthy / unhealthy
docker inspect --format='{{json .State.Health}}' employee-backend

---

## S18 — docker cp
docker cp employee-backend:/app/employee-api.jar ./backup.jar   # copy out
docker cp config.txt employee-backend:/app/config.txt            # copy in

 1. Copy jar OUT
docker cp employee-backend:/app/employee-api.jar ./backup.jar
ls -lh backup.jar

 2. Copy hosts file OUT (see Docker DNS entries)
docker cp employee-backend:/etc/hosts ./container-hosts.txt
cat container-hosts.txt

 3. Create file and copy IN
echo "test=true" > test.properties
docker cp test.properties employee-backend:/app/test.properties
docker exec employee-backend cat /app/test.properties

 4. Copy on STOPPED container
docker stop employee-backend
docker cp employee-backend:/app/employee-api.jar ./stopped-backup.jar
ls -lh stopped-backup.jar    # works even when stopped ✅
docker start employee-backend

 5. Copy entire folder out
docker cp employee-backend:/app ./full-app-backup
ls ./full-app-backup
---

## S19 — Full Deployment Simulation
docker compose build
docker tag employee-backend:1.0 myrepo/employee-backend:v1.0
docker compose up -d
docker compose ps
curl http://localhost:8080/actuator/health
curl http://localhost:8080/api/employees

---

## S20 — Cleanup
docker system df                 # see disk usage
docker system prune              # safe cleanup
docker system prune -a           # remove all unused images too
docker volume prune              # remove unused volumes (data loss risk!)
