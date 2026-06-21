// ═══════════════════════════════════════════════════════════════════
// Jenkinsfile — CI/CD Pipeline for Employee Management Docker Project
//
// Pipeline stages:
//   1. Checkout      — pull code from Git
//   2. Build          — docker compose build backend
//   3. Test           — verify image was built, run smoke checks
//   4. Tag            — tag image with Jenkins BUILD_NUMBER
//   5. Push           — push to Docker Hub / local registry
//   6. Deploy         — docker compose up -d --force-recreate
//   7. Smoke Test     — curl health endpoint to verify deployment
//   8. Cleanup        — remove old dangling images
// ═══════════════════════════════════════════════════════════════════

pipeline {
    agent any

    environment {
        // Change this to your Docker Hub username
        DOCKER_REGISTRY   = "sampath369"
        IMAGE_NAME        = "employee-backend"
        FRONTEND_IMAGE    = "employee-frontend"
        // Jenkins credential ID for Docker Hub (set up in Jenkins UI)
        DOCKERHUB_CREDS   = credentials('dockerhub-credentials')
    }

    stages {

        // ── STAGE 1: Checkout code from Git ──────────────────────
        stage('Checkout') {
            steps {
                echo "===== Checking out source code ====="
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        // ── STAGE 2: Build Docker images ─────────────────────────
        stage('Build') {
            steps {
                echo "===== Building Docker images ====="
                sh 'docker compose build backend'
                sh 'docker compose build frontend'
            }
        }

        // ── STAGE 3: Test — verify build succeeded ───────────────
        stage('Test') {
            steps {
                echo "===== Running smoke tests on built image ====="
                sh '''
                    docker run --rm --entrypoint java ${IMAGE_NAME}:1.0  -version
                    docker images | grep ${IMAGE_NAME}
                '''
            }
        }

        // ── STAGE 4: Tag image with build number ─────────────────
        stage('Tag') {
            steps {
                echo "===== Tagging image with build number ${BUILD_NUMBER} ====="
                sh '''
                    docker tag ${IMAGE_NAME}:1.0 ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker tag ${IMAGE_NAME}:1.0 ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
                    docker tag ${FRONTEND_IMAGE}:1.0 ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${BUILD_NUMBER}
                    docker tag ${FRONTEND_IMAGE}:1.0 ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:latest
                '''
            }
        }

        // ── STAGE 5: Push to registry ─────────────────────────────
        stage('Push to Registry') {
            steps {
                echo "===== Pushing images to Docker Hub ====="
                sh '''
                    echo $DOCKERHUB_CREDS_PSW | docker login -u $DOCKERHUB_CREDS_USR --password-stdin
                    docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
                    docker push ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${BUILD_NUMBER}
                    docker push ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:latest
                '''
            }
        }

        // ── STAGE 6: Deploy ────────────────────────────────────────
        stage('Deploy') {
            steps {
                echo "===== Deploying updated containers ====="
                sh '''
                    docker compose up -d --force-recreate backend
                    docker compose up -d --force-recreate frontend
                '''
            }
        }

        // ── STAGE 7: Smoke test after deployment ─────────────────
        stage('Smoke Test') {
            steps {
                echo "===== Verifying deployment health ====="
                sh '''
                    sleep 15
                    curl -f http://localhost:8080/actuator/health || exit 1
                    curl -f http://localhost:8080/api/employees || exit 1
                '''
            }
        }

        // ── STAGE 8: Cleanup old images ───────────────────────────
        stage('Cleanup') {
            steps {
                echo "===== Cleaning up dangling images ====="
                sh 'docker image prune -f'
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline succeeded — Build #${BUILD_NUMBER} deployed successfully"
        }
        failure {
            echo "❌ Pipeline failed — check logs above for the failing stage"
        }
        always {
            echo "===== Pipeline finished: ${currentBuild.result} ====="
        }
    }
}
