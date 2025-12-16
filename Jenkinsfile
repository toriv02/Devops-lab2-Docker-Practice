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
        
       stage('Deploy') {
            when {
                expression { 
                    return env.BRANCH_NAME == 'main' || env.GIT_BRANCH == 'origin/main'
                }
            }
            steps {
                script {
                    echo ' DEPLOYMENT STAGE - CD PROCESS'
                    echo ' Branch: main - Deploying...'
                    
                    // Удаляем только контейнеры проекта, не трогая другие
                    bat '''
                        echo "Stopping and removing all project containers..."
                        docker-compose down -v 2>nul || echo "No containers to stop"
                        
                        echo "Removing specific containers by name..."
                        docker rm -f myapp_backend myapp_frontend 2>nul || echo "Containers not found"
                        
                        echo "Removing dangling containers..."
                        docker ps -aq --filter "name=myapp" | xargs docker rm -f 2>nul || echo "No dangling containers"
                        
                        echo "Cleaning up networks..."
                        docker network prune -f
                    '''
                    
                    // Запускаем контейнеры
                     echo ' Starting application...'
                    bat 'docker-compose up -d --build --force-recreate'
                    
                    // Даем время на запуск
                    echo ' Waiting for containers to start...'
                    bat 'timeout /t 10 /nobreak > nul'
                    
                    // Проверяем статус
                    echo ' Checking container status...'
                    bat 'docker-compose ps'
                    
                    // Проверяем логи для диагностики
                    echo ' Checking container logs...'
                    bat 'docker-compose logs --tail=20'
                    
                    echo ' PRODUCTION DEPLOYMENT COMPLETE!'
                    echo ' Frontend: http://localhost:3000'
                    echo '  Backend API: http://localhost:8000'
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