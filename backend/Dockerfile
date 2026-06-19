# ═══════════════════════════════════════════════════════
# STAGE 1 – BUILD  (Maven + JDK 17)
# This stage compiles the code and produces employee-api.jar
# After build, Maven + source code are DISCARDED.
# ═══════════════════════════════════════════════════════
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /build

# Copy pom.xml first → Docker caches dependency layer separately
# Re-run mvn install only when pom.xml changes (faster rebuilds)
COPY pom.xml .
RUN mvn dependency:go-offline -q

# Copy source and build
COPY src ./src
RUN mvn clean package -DskipTests -q

# ═══════════════════════════════════════════════════════
# STAGE 2 – RUNTIME  (JRE only — much smaller image)
# Only the JAR is copied from Stage 1.
# Maven, source, test classes are gone.
# ═══════════════════════════════════════════════════════
FROM eclipse-temurin:17-jre-alpine

# Security: create non-root user (interview concept: container security)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only the built JAR from builder stage
COPY --from=builder /build/target/employee-api.jar employee-api.jar

# Give ownership to appuser
RUN chown appuser:appgroup employee-api.jar

# Switch to non-root user
USER appuser

# Document the port (does NOT publish — that's done at docker run)
EXPOSE 8080

# ENTRYPOINT = fixed part (always runs java -jar)
# CMD        = default argument (can be overridden at runtime)
ENTRYPOINT ["java", "-jar"]
CMD ["employee-api.jar"]
#MD ["wrong-api.jar"]
# Health check — Docker will mark container healthy/unhealthy
# Checks every 30s, 3 retries, 40s startup grace period
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1
