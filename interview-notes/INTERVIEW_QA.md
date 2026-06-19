# Docker Interview Q&A — Based on This Project

---

Q: What is the difference between CMD and ENTRYPOINT?
A: ENTRYPOINT defines the fixed executable. CMD provides default arguments.
   If both are set, they combine: ENTRYPOINT runs CMD as its argument.
   CMD can be overridden by passing arguments to docker run.
   ENTRYPOINT can be overridden only with --entrypoint flag.
   Our backend: ENTRYPOINT ["java","-jar"] CMD ["employee-api.jar"]

---

Q: Why did you use multi-stage build?
A: Stage 1 (Maven+JDK) compiles and packages the JAR.
   Stage 2 (JRE only) copies only the JAR.
   Result: ~250MB vs ~800MB. Smaller image = faster pulls, smaller attack surface.
   Maven, source code, and test files never reach production.

---

Q: How do containers in your stack communicate?
A: Via a custom Docker bridge network (employee-net).
   Docker has a built-in DNS that resolves service names to container IPs.
   Backend uses jdbc:mysql://mysql:3306 — "mysql" resolves to the mysql container.
   We never hardcode IP addresses. IPs change; service names don't.

---

Q: How did you make data persist for MySQL?
A: Named volume: employee_mysql-data mounted at /var/lib/mysql.
   Even if the mysql container is deleted, the volume survives.
   docker compose down removes containers. docker compose down -v removes volumes too.

---

Q: What is Exit Code 137?
A: Out-of-memory kill. The Linux kernel OOM killer terminated the container.
   Triggered when container exceeds its --memory limit.
   Fix: Increase memory limit or tune JVM heap with -Xmx.

---

Q: How do you troubleshoot a container that exits immediately?
A: 1. docker ps -a → check exit code
   2. docker logs <name> → read the error
   3. Exit 1 = app error, Exit 127 = command not found, Exit 137 = OOM
   4. docker inspect <name> → check config/env vars
   5. docker run -it --entrypoint sh <image> → get shell, debug manually

---

Q: Why did you run the container as a non-root user?
A: If the application is compromised, root inside a container can potentially
   escape to the host. Non-root limits blast radius.
   In Dockerfile: RUN addgroup -S appgroup && adduser -S appuser -G appgroup
                  USER appuser
   Verify: docker exec employee-backend whoami → appuser

---

Q: What does docker stats show?
A: Real-time CPU %, memory usage vs limit, network I/O, block I/O.
   Used to identify resource bottlenecks, OOM risk, and noisy containers.

---

Q: What is a health check and why does it matter?
A: Docker periodically runs a test command against the container.
   Status: starting → healthy (passes) or unhealthy (fails).
   In Compose: depends_on with condition: service_healthy ensures
   backend only starts after MySQL is confirmed healthy — not just running.

---

Q: What is restart: unless-stopped?
A: Container auto-restarts if it crashes or the Docker daemon restarts.
   Stops only if explicitly stopped with docker stop.
   Other policies: no (default), always, on-failure.

---

Q: What is docker network inspect used for?
A: Shows subnet, gateway, and which containers are connected to a network.
   Shows each container's IP and how Docker's DNS maps names to IPs.
   Used to debug connectivity issues between containers.
