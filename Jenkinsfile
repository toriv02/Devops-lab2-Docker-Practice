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
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    def branch = bat(
                        script: 'git branch --show-current',
                        returnStdout: true
                    ).trim()
                    env.GIT_BRANCH = branch
                    echo "Build for branch: ${env.GIT_BRANCH}"
                    
                    def changesRaw = bat(
                        script: 'git diff --name-only HEAD~1 HEAD 2>nul || echo ""',
                        returnStdout: true
                    ).trim()
                    
                    def changedFiles = changesRaw ? changesRaw.split(/\r?\n/).collect { it.trim() }.findAll { it } : []
                    
                    env.CHANGED_FRONTEND = changedFiles.any { 
                        it.startsWith("${env.FRONTEND_DIR}/") 
                    }.toString()
                    
                    env.CHANGED_BACKEND = changedFiles.any { 
                        it.startsWith("${env.BACKEND_DIR}/") || it == 'requirements.txt' || it == 'manage.py'
                    }.toString()
                    
                    echo "Frontend changed: ${env.CHANGED_FRONTEND}, Backend changed: ${env.CHANGED_BACKEND}"
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                script {
                    if (env.CHANGED_FRONTEND == 'true') {
                        dir(env.FRONTEND_DIR) {
                            bat 'npm ci --silent'
                            echo "Frontend dependencies installed"
                        }
                    }
                    
                    if (env.CHANGED_BACKEND == 'true') {
                        def pythonPath = "C:\\Users\\Admin\\AppData\\Local\\Programs\\Python\\Python314\\python.exe"
                        def exists = bat(
                            script: "@echo off && if exist \"${pythonPath}\" (echo EXISTS) else (echo NOT_FOUND)",
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
                    def branch = env.GIT_BRANCH ?: ''
                    return branch != 'main' && branch != 'master'
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
                            )
                        """
                    }
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    boolean buildFrontend = env.CHANGED_FRONTEND == 'true'
                    boolean buildBackend = env.CHANGED_BACKEND == 'true'
                    
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
                    boolean buildFrontend = env.CHANGED_FRONTEND == 'true'
                    boolean buildBackend = env.CHANGED_BACKEND == 'true'
                    
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
                        
                        // Убрали docker logout отсюда - credentials управляются Jenkins
                        echo 'Images pushed to Docker Hub!'
                    }
                }
            }
        }
        
        stage('Deploy') {
            when {
                expression {
                    def branch = env.GIT_BRANCH ?: ''
                    return (branch == 'main' || branch == 'master') &&
                           (env.CHANGED_FRONTEND == 'true' || env.CHANGED_BACKEND == 'true')
                }
            }
            steps {
                script {
                    echo '=== DEPLOYING TO PRODUCTION ==='
                    echo 'Branch: main/master - starting deploy'
                    
                    def composeExists = bat(
                        script: '@echo off && if exist "docker-compose.yml" (echo EXISTS) else (echo NOT_FOUND)',
                        returnStdout: true
                    ).trim()
                    
                    if (!composeExists.contains("EXISTS")) {
                        error "docker-compose.yml not found!"
                    }
                    
                    echo 'Stopping old containers...'
                    bat '''
                        @echo off
                        echo Stopping existing containers...
                        docker-compose down --remove-orphans 2>nul || echo "No containers to stop"
                        docker-compose down -v 2>nul || echo "Cleanup done"
                    '''
                    
                    echo 'Pulling latest images...'
                    bat '''
                        @echo off
                        echo Pulling images...
                        docker-compose pull || echo "Pull completed"
                    '''
                    
                    echo 'Starting application...'
                    bat '''
                        @echo off
                        echo Starting containers...
                        docker-compose up -d --build
                        timeout /t 15 /nobreak > nul
                    '''
                    
                    echo 'Checking container status...'
                    bat '''
                        @echo off
                        echo "=== CONTAINER STATUS ==="
                        docker-compose ps
                        echo.
                        echo "=== LOGS ==="
                        docker-compose logs --tail=10
                    '''
                    
                    echo '=== DEPLOYMENT COMPLETE ==='
                    echo 'Frontend: http://localhost:3000'
                    echo 'Backend API: http://localhost:8000'
                    echo 'Database: localhost:1433'
                    
                    env.DEPLOY_PERFORMED = 'true'
                }
            }
        }
    }
    
    post {
        success {
            script {
                if (env.DEPLOY_PERFORMED == 'true') {
                    echo '=== CD PIPELINE SUCCESS ==='
                    echo 'Application deployed to production!'
                } else {
                    echo '=== CI PIPELINE SUCCESS ==='
                    echo 'Build and tests passed'
                }
            }
        }
        failure {
            echo '=== PIPELINE FAILED ==='
            bat '''
                @echo off
                echo Cleaning up after failure...
                docker-compose down 2>nul && echo "Containers stopped" || echo "No containers to stop"
            '''
        }
        always {
            echo "Build status: ${currentBuild.result ?: 'SUCCESS'}"
            echo "Branch: ${env.GIT_BRANCH ?: 'not defined'}"
            echo "Duration: ${currentBuild.durationString}"
            cleanWs()
        }
    }
}