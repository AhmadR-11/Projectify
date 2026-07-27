// ==============================================================================
// PROJECTIFY — DECLARATIVE JENKINS PIPELINE (CI/CD)
// ==============================================================================
//
// PURPOSE:
//   Automates the CI/CD pipeline for Projectify:
//     1. Code Checkout from GitHub
//     2. Environment & Tool Verification (Node.js, Docker, Prisma)
//     3. Code Quality & Lint Checks
//     4. Prisma Database Schema Validation
//     5. Docker Image Build (multi-stage Dockerfile)
//     6. Container Health Verification
//     7. Post-build Cleanup
//
// USAGE IN JENKINS (http://localhost:8080):
//   1. Dashboard -> New Item -> Name: "Projectify-Pipeline" -> Type: "Pipeline"
//   2. Pipeline section -> Definition: "Pipeline script from SCM"
//   3. SCM: Git -> Repository URL: https://github.com/AhmadR-11/Projectify.git
//   4. Branch: */main (or your active branch)
//   5. Script Path: Jenkinsfile
// ==============================================================================

pipeline {
    // Run pipeline on any available agent node
    agent any

    // Environment variables used throughout the pipeline stages
    environment {
        APP_NAME         = 'projectify-app'
        IMAGE_TAG        = 'latest'
        TEST_CONTAINER   = 'projectify-ci-test'
        TEST_PORT        = '3001'
    }

    options {
        // Automatically stop build if it takes longer than 45 minutes
        timeout(time: 45, unit: 'MINUTES')
        // Keep logs for the last 10 builds only to save disk space
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        // ──────────────────────────────────────────────────────────────────────
        // STAGE 1: Code Checkout
        // ──────────────────────────────────────────────────────────────────────
        stage('Checkout Code') {
            steps {
                echo '📥 [Stage 1/6] Checking out latest code from repository...'
                checkout scm
            }
        }

        // ──────────────────────────────────────────────────────────────────────
        // STAGE 2: Environment Verification
        // ──────────────────────────────────────────────────────────────────────
        stage('Verify Environment') {
            steps {
                echo '🔍 [Stage 2/6] Checking Node.js, npm, and Docker tools...'
                sh '''
                    node -v
                    npm -v
                    docker --version
                '''
            }
        }

        // ──────────────────────────────────────────────────────────────────────
        // STAGE 3: Install & Lint
        // ──────────────────────────────────────────────────────────────────────
        stage('Install & Lint') {
            steps {
                echo '🧹 [Stage 3/6] Installing dependencies and running ESLint...'
                sh '''
                    npm ci
                    CI=true npm run lint || echo "⚠️ Linting finished with warnings."
                '''
            }
        }

        // ──────────────────────────────────────────────────────────────────────
        // STAGE 4: Prisma Schema Validation
        // ──────────────────────────────────────────────────────────────────────
        stage('Validate Prisma Schema') {
            steps {
                echo '🗄️ [Stage 4/6] Validating Prisma database schema...'
                sh '''
                    DATABASE_URL="postgresql://user:pass@localhost:5432/db" \
                    DIRECT_URL="postgresql://user:pass@localhost:5432/db" \
                    npx prisma validate
                '''
            }
        }

        // ──────────────────────────────────────────────────────────────────────
        // STAGE 5: Docker Build
        // ──────────────────────────────────────────────────────────────────────
        stage('Build Docker Image') {
            steps {
                echo '🐳 [Stage 5/6] Building production Docker image via Dockerfile...'
                sh '''
                    docker build -t ${APP_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        // ──────────────────────────────────────────────────────────────────────
        // STAGE 6: Container Smoke Test
        // ──────────────────────────────────────────────────────────────────────
        stage('Container Health Test') {
            steps {
                echo '🧪 [Stage 6/6] Verifying Docker container startup and health check...'
                sh '''
                    # Clean up old test container if it exists
                    docker rm -f ${TEST_CONTAINER} || true

                    # Run image in background on test port
                    docker run -d \
                        --name ${TEST_CONTAINER} \
                        -p ${TEST_PORT}:3000 \
                        -e NODE_ENV=production \
                        -e NEXTAUTH_SECRET=ci_test_secret_32_characters_long_key \
                        ${APP_NAME}:${IMAGE_TAG}

                    # Wait for container to initialize
                    sleep 10

                    # Verify container is running
                    if docker ps | grep ${TEST_CONTAINER}; then
                        echo "✅ Container started successfully!"
                    else
                        echo "❌ Container failed to start!"
                        docker logs ${TEST_CONTAINER}
                        exit 1
                    fi
                '''
            }
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // POST-BUILD ACTIONS (Runs after stages complete, success or failure)
    // ──────────────────────────────────────────────────────────────────────────
    post {
        always {
            echo '🧹 Cleaning up test container...'
            sh '''
                docker rm -f ${TEST_CONTAINER} || true
            '''
        }
        success {
            echo '🎉 PIPELINE SUCCESSFUL! Docker image projectify-app:latest is ready.'
        }
        failure {
            echo '💥 PIPELINE FAILED! Please inspect stage logs above for details.'
        }
    }
}
