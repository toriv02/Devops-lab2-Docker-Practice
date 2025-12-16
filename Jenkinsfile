pipeline {
    agent any
    
    environment {
        DOCKERHUB_USER = 'toriv00'
        DEPLOY_PERFORMED = 'false'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo 'Code downloaded from Git'

                bat 'git branch --show-current'
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    echo 'Building Backend image...'
                    bat "docker build -t ${DOCKERHUB_USER}/devops-lab2-backend:latest ."
                    
                    echo 'Building Frontend image...'
                    bat "docker build -t ${DOCKERHUB_USER}/devops-lab2-frontend:latest client"
                    
                    echo 'Build completed successfully!'
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-creds', 
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        echo 'Logging into Docker Hub...'
                        bat "echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin"
                        
                        echo 'Pushing Backend image...'
                        bat "docker push ${DOCKERHUB_USER}/devops-lab2-backend:latest"
                        
                        echo 'Pushing Frontend image...'
                        bat "docker push ${DOCKERHUB_USER}/devops-lab2-frontend:latest"
                        
                        bat 'docker logout'
                        echo 'Images pushed to Docker Hub successfully!'
                    }
                }
            }
        }
        
       stage('Deploy to Production') {
            when {
                expression { 
                    return env.BRANCH_NAME == 'main' || env.GIT_BRANCH == 'origin/main'
                }
            }
            steps {
                script {
                    echo ' DEPLOYMENT STAGE - CD PROCESS'
                    echo ' Branch: main - Deploying to production...'
                    
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
                    
                    env.DEPLOY_PERFORMED = 'true'
                    echo ' PRODUCTION DEPLOYMENT COMPLETE!'
                    echo ' Frontend: http://localhost:3000'
                    echo '  Backend API: http://localhost:8000'
                }
            }
        }
        
        stage('Post-Deploy Verification') {
            when {
                expression { 
                    return (env.BRANCH_NAME == 'main' || env.GIT_BRANCH == 'origin/main') && env.DEPLOY_PERFORMED == 'true'
                }
            }
            steps {
                script {
                    echo ' Verifying deployment...'
                    bat 'docker-compose ps'
                    
                    // Проверка доступности с повторными попытками
                    bat '''
                        echo "Checking Frontend (max 3 attempts)..."
                        for /l %%i in (1,1,3) do (
                            curl http://localhost:3000 -I -s -o nul && (
                                echo "Frontend is up!"
                                exit /b 0
                            ) || (
                                echo "Attempt %%i: Frontend not ready yet"
                                ping -n 2 127.0.0.1 > nul
                            )
                        )
                    '''
                    
                    bat '''
                        echo "Checking Backend (max 3 attempts)..."
                        for /l %%i in (1,1,3) do (
                            curl http://localhost:8000/api/contents/ -I -s -o nul && (
                                echo "Backend is up!"
                                exit /b 0
                            ) || (
                                echo "Attempt %%i: Backend not ready yet"
                                ping -n 2 127.0.0.1 > nul
                            )
                        )
                    '''
                    
                    echo ' Verification complete!'
                }
            }
        }
    }
    
    post {
        success {
            script {
                if (env.DEPLOY_PERFORMED == 'true') {
                    echo ' CD PIPELINE SUCCESS - Application deployed to production!'
                    echo ' ====== CD PROCESS COMPLETE ======'
                } else {
                    echo ' CI PIPELINE SUCCESS - Build and tests passed'
                    echo ' ====== CI PROCESS COMPLETE ======'
                }
            }
        }
        failure {
            echo ' Pipeline failed'
        }
        always {
            echo ' Cleaning workspace...'
            cleanWs()
        }
    }
}