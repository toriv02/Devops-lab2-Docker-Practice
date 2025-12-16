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
                    echo 'DEPLOYMENT STAGE - CD PROCESS'

                      bat '''
                        docker-compose down 2>nul || echo "Stopping old containers..."
                        docker-compose up -d --build
                        ping -n 15 127.0.0.1 > nul
                        echo "=== APPLICATION STATUS ==="
                        docker-compose ps
                        echo "Frontend: http://localhost:3000"
                        echo "Backend:  http://localhost:8000"
                        echo "=== DEPLOYMENT COMPLETE ==="
                    '''
            
                    env.DEPLOY_PERFORMED = 'true
                }
            }
        }
        
        stage('Post-Deploy Verification') {
            when {
                branch 'main'
                expression { env.DEPLOY_PERFORMED == 'true' }
            }
            steps {
                script {
                    echo 'Verifying deployment...'
                    bat 'docker-compose ps'
                    bat 'curl http://localhost:3000 -I 2>nul || echo "Frontend starting..."'
                    bat 'curl http://localhost:8000 -I 2>nul || echo "Backend starting..."'
                    echo 'Verification complete!'
                }
            }
        }
    }
    
    post {
        success {
            script {
                if (env.DEPLOY_PERFORMED == 'true') {
                    echo 'CD PIPELINE SUCCESS - Application deployed to production!'
                    echo '====== CD PROCESS COMPLETE ======'
                } else {
                    echo ' CI PIPELINE SUCCESS - Build and tests passed'
                    echo ' ====== CI PROCESS COMPLETE ======'
                }
            }
        }
        failure {
            echo 'Pipeline failed'
        }
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
    }
}