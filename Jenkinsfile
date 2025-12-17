pipeline {
    agent any
    
    environment {
        FRONTEND_DIR = 'client'
        BACKEND_DIR = 'project'
        DOCKERHUB_USER = 'toriv00'
        FRONTEND_IMAGE = "${DOCKERHUB_USER}/devops-lab2-frontend"
        BACKEND_IMAGE = "${DOCKERHUB_USER}/devops-lab2-backend"
        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'
        DEPLOY_PATH = '.'
        DEPLOY_CONFIG_NAME = 'docker-compose.yml'
        COMPOSE_PROJECT_NAME = 'devopslab2'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    extensions: [[$class: 'LocalBranch', localBranch: 'main']],
                    userRemoteConfigs: [[url: 'https://github.com/toriv02/Devops-lab2-Docker-Practice']]
                ])
                
                script {
                    
                    def branch = bat(
                        script: '@echo off && git rev-parse --abbrev-ref HEAD',
                        returnStdout: true
                    ).trim()
                    
                    // Убираем 'origin/' если есть
                    env.GIT_BRANCH = branch.replace('origin/', '')
                    echo "Build for branch: ${env.GIT_BRANCH}"
                    
                    // Получаем список измененных файлов
                    def changesRaw = bat(
                        script: '@echo off && git diff --name-only HEAD~1 HEAD 2>nul || git show --name-only --pretty="" HEAD 2>nul',
                        returnStdout: true
                    ).trim()
                    
                    def changedFiles = changesRaw ? changesRaw.split(/\r?\n/).collect { it.trim() }.findAll { it } : []
                    
                    env.CHANGED_FRONTEND = changedFiles.any { 
                        it.startsWith("${env.FRONTEND_DIR}/") || it.contains("/${env.FRONTEND_DIR}/")
                    }.toString()
                    
                    env.CHANGED_BACKEND = changedFiles.any { 
                        it.startsWith("${env.BACKEND_DIR}/") || 
                        it.contains("/${env.BACKEND_DIR}/") || 
                        it == 'requirements.txt' || 
                        it == 'manage.py' ||
                        it.endsWith('.py')
                    }.toString()
                    
                    echo "Frontend changed: ${env.CHANGED_FRONTEND}, Backend changed: ${env.CHANGED_BACKEND}"
                    echo "Changed files: ${changedFiles}"
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                script {
                    if (env.CHANGED_FRONTEND == 'true' || (env.GIT_BRANCH == 'main' || env.GIT_BRANCH == 'origin/main') ) {
                        dir(env.FRONTEND_DIR) {
                            bat '@echo off && npm ci --silent'
                            echo "Frontend dependencies installed"
                        }
                    }
                    
                    if (env.CHANGED_BACKEND == 'true' || (env.GIT_BRANCH == 'main' || env.GIT_BRANCH == 'origin/main')) {
                        def pythonPath = "C:\\Users\\Admin\\AppData\\Local\\Programs\\Python\\Python314\\python.exe"
                        def exists = bat(
                            script: '@echo off && if exist "${pythonPath}" (echo EXISTS) else (echo NOT_FOUND)',
                            returnStdout: true
                        ).trim()
                        
                        if (exists.contains("EXISTS")) {
                            env.PYTHON_PATH = pythonPath
                            bat """
                                @echo off
                                echo Using Python from: ${env.PYTHON_PATH}
                                
                                if exist "requirements.txt" (
                                    echo Installing Python dependencies...
                                    "${env.PYTHON_PATH}" -m pip install -r requirements.txt
                                ) else (
                                    echo requirements.txt not found
                                    "${env.PYTHON_PATH}" -m pip install django djangorestframework
                                )
                            """
                            echo "Backend dependencies installed"
                        }
                    }
                }
            }
        }
        
        stage('Run Tests') {
            when {
                expression {
                    return env.GIT_BRANCH != 'main'
                }
            }
            steps {
                script {
                    if (env.PYTHON_PATH && env.CHANGED_BACKEND == 'true') {
                        echo "Running Django tests"
                        bat """
                            @echo off
                            if exist "manage.py" (
                                echo Running Django tests...
                                "${env.PYTHON_PATH}" manage.py test --verbosity=2
                            ) else (
                                echo manage.py not found
                            )
                        """
                    }
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    boolean buildFrontend = env.CHANGED_FRONTEND == 'true' || (env.GIT_BRANCH == 'main' || env.GIT_BRANCH == 'origin/main')
                    boolean buildBackend = env.CHANGED_BACKEND == 'true' || (env.GIT_BRANCH == 'main' || env.GIT_BRANCH == 'origin/main')
                    
                    if (!buildFrontend && !buildBackend) {
                        echo 'No changes - skipping Docker build'
                        return
                    }
                    
                    echo 'Building Docker images...'
                    
                    if (buildBackend) {
                        echo 'Building Backend image...'
                        bat "docker build -t ${env.BACKEND_IMAGE}:latest ."
                    }
                    
                    if (buildFrontend) {
                        echo 'Building Frontend image...'
                        bat "docker build -t ${env.FRONTEND_IMAGE}:latest ${env.FRONTEND_DIR}"
                    }
                    
                    echo 'Docker images built successfully!'
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    boolean buildFrontend = env.CHANGED_FRONTEND == 'true' || (env.GIT_BRANCH == 'main' || env.GIT_BRANCH == 'origin/main')
                    boolean buildBackend = env.CHANGED_BACKEND == 'true' || (env.GIT_BRANCH == 'main' || env.GIT_BRANCH == 'origin/main')
                    
                    if (!buildFrontend && !buildBackend) {
                        echo 'No changes - skipping Docker Hub push'
                        return
                    }
                    
                    withCredentials([usernamePassword(
                        credentialsId: env.DOCKERHUB_CREDENTIALS,
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        echo 'Logging into Docker Hub...'
                        bat "echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin"
                        
                        if (buildBackend) {
                            echo 'Pushing Backend image...'
                            bat "docker push ${env.BACKEND_IMAGE}:latest"
                        }
                        
                        if (buildFrontend) {
                            echo 'Pushing Frontend image...'
                            bat "docker push ${env.FRONTEND_IMAGE}:latest"
                        }
                        
                        echo 'Images pushed to Docker Hub!'
                    }
                }
            }
        }
        
<<<<<<< HEAD
       stage('Deploy') {
            when {
                expression { 
                    return env.BRANCH_NAME == 'main' || env.GIT_BRANCH == 'origin/main'
=======
        stage('Deploy') {
            when {
                expression {
                    return (env.GIT_BRANCH == 'main' || env.GIT_BRANCH == 'origin/main') && (env.CHANGED_FRONTEND == 'true' || env.CHANGED_BACKEND == 'true')
>>>>>>> main
                }
            }
            steps {
                script {
<<<<<<< HEAD
                    echo ' DEPLOYMENT STAGE - CD PROCESS'
                    echo ' Branch: main - Deploying...'
                    
                    // Удаляем только контейнеры проекта, не трогая другие
                    bat '''
                        echo Stopping project containers...
                        docker-compose down 2>nul || echo "No project containers to stop"
                        
                        echo Removing specific containers if they exist...
                        docker rm -f myapp_backend myapp_frontend 2>nul || echo "Containers not found"
                        
                        echo Cleaning up unused resources...
                        docker network prune -f 2>nul
                    '''
                    
                    // Запускаем контейнеры
                    echo ' Starting application...'
                    bat 'docker-compose up -d --build'
                    
                    // Вместо timeout используем ping для ожидания (работает в Windows)
                    echo ' Waiting for containers to start...'
                    bat 'ping -n 10 127.0.0.1 > nul'
                    
                    // Проверяем статус
                    echo ' Checking container status...'
                    bat 'docker-compose ps'
                    
                    echo ' PRODUCTION DEPLOYMENT COMPLETE!'
                    echo ' Frontend: http://localhost:3000'
                    echo '  Backend API: http://localhost:8000'
=======
                    echo '=== DEPLOYING TO PRODUCTION ==='
                    echo "Branch: ${env.GIT_BRANCH} - starting deploy"
                    
                    def composeExists = bat(
                        script: '@echo off && if exist "docker-compose.yml" (echo EXISTS) else (echo NOT_FOUND)',
                        returnStdout: true
                    ).trim()
                    
                    if (!composeExists.contains("EXISTS")) {
                        error "docker-compose.yml not found!"
                    }
                    
                    // Проверяем, какая команда docker compose доступна
                    def composeCmdCheck = bat(
                        script: '@echo off && docker compose version 2>nul && echo docker-compose || echo docker-compose',
                        returnStdout: true
                    ).trim()
                    
                    def composeCmd = composeCmdCheck.contains("docker compose") ? "docker compose" : "docker-compose"
                    echo "Using compose command: ${composeCmd}"
                    
                    echo 'Stopping old containers...'
                    bat """
                        @echo off
                        echo Stopping existing containers...
                        ${composeCmd} -p ${env.COMPOSE_PROJECT_NAME} down --remove-orphans 2>nul || echo "No containers to stop"
                        
                        echo Checking for containers using port 8000...
                        for /f "tokens=*" %%i in ('docker ps -q --filter "publish=8000"') do (
                            echo Stopping container %%i using port 8000...
                            docker stop %%i 2>nul || echo "Failed to stop container %%i"
                            docker rm %%i 2>nul || echo "Failed to remove container %%i"
                        )
                        
                        echo Checking for containers using port 3000...
                        for /f "tokens=*" %%i in ('docker ps -q --filter "publish=3000"') do (
                            echo Stopping container %%i using port 3000...
                            docker stop %%i 2>nul || echo "Failed to stop container %%i"
                            docker rm %%i 2>nul || echo "Failed to remove container %%i"
                        )
                        
                        echo Checking for containers using port 1433...
                        for /f "tokens=*" %%i in ('docker ps -q --filter "publish=1433"') do (
                            echo Stopping container %%i using port 1433...
                            docker stop %%i 2>nul || echo "Failed to stop container %%i"
                            docker rm %%i 2>nul || echo "Failed to remove container %%i"
                        )
                        
                        echo Checking for orphaned containers...
                        docker system prune -f 2>nul || echo "Cleanup completed"
                    """
                    
                    echo 'Pulling latest images...'
                    bat """
                        @echo off
                        echo Pulling images...
                        ${composeCmd} -p ${env.COMPOSE_PROJECT_NAME} pull --quiet || echo "Pull completed"
                    """
                    
                    echo 'Starting application...'
                    bat """
                        @echo off
                        echo Starting containers...
                        ${composeCmd} -p ${env.COMPOSE_PROJECT_NAME} up -d --force-recreate --build
    
                        
                        echo Waiting for services to start...
                        ping -n 20 127.0.0.1 > nul
                    """
                    
                    echo 'Checking container status...'
                    bat """
                        @echo off
                        echo "=== CONTAINER STATUS ==="
                        ${composeCmd} -p ${env.COMPOSE_PROJECT_NAME} ps
                        echo.
                        echo "=== CONTAINER HEALTH ==="
                        for /f "tokens=*" %%i in ('${composeCmd} -p ${env.COMPOSE_PROJECT_NAME} ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"') do (
                            echo %%i
                        )
                        echo.
                        echo "=== LOGS (last 15 lines) ==="
                        ${composeCmd} -p ${env.COMPOSE_PROJECT_NAME} logs --tail=15
                    """
                    
                    echo '=== DEPLOYMENT COMPLETE ==='
                    echo 'Frontend: http://localhost:3000'
                    echo 'Backend API: http://localhost:8000'
                    echo 'Database: localhost:1433'
                    
                    env.DEPLOY_PERFORMED = 'true'
>>>>>>> main
                }
            }
        }
    }    
    
    post {
        success {
            script {
                if (env.DEPLOY_PERFORMED == 'true') {
<<<<<<< HEAD
                    echo ' CD PIPELINE SUCCESS - Application deployed to production!'
                    echo ' ====== CD PROCESS COMPLETE ======'
=======
                    echo '=== CD PIPELINE SUCCESS ==='
                    echo 'Application deployed to production!'
>>>>>>> main
                } else {
                    echo '=== CI PIPELINE SUCCESS ==='
                    echo 'Build and tests passed'
                }
            }
        }
        failure {
<<<<<<< HEAD
            echo ' Pipeline failed'
        }
        always {
            echo ' Cleaning workspace...'
=======
            echo '=== PIPELINE FAILED ==='
            bat """
                @echo off
                echo Cleaning up after failure...
                docker-compose -p ${env.COMPOSE_PROJECT_NAME} down --remove-orphans 2>nul && echo "Containers stopped" || echo "No containers to stop"
                echo "Checking for hanging containers..."
                docker ps -a | findstr ${env.COMPOSE_PROJECT_NAME} && echo "Found containers from project" || echo "No project containers found"
            """
        }
        always {
            echo "Build status: ${currentBuild.result ?: 'SUCCESS'}"
            echo "Branch: ${env.GIT_BRANCH ?: 'not defined'}"
            echo "Duration: ${currentBuild.durationString}"
>>>>>>> main
            cleanWs()
        }
    }
}