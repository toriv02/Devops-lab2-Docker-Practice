pipeline {
    agent any
    
    environment {
        DOCKERHUB_USER = 'toriv00'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo ' Code downloaded from Git'
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    echo ' Building Backend image...'
                    bat "docker build -t ${DOCKERHUB_USER}/devops-lab2-backend:latest ."
                    
                    echo ' Building Frontend image...'
                    bat "docker build -t ${DOCKERHUB_USER}/devops-lab2-frontend:latest client"
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
                        echo ' Logging into Docker Hub...'

                        bat "echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin"
                        
                        echo ' Pushing Backend image...'
                        bat "docker push ${DOCKERHUB_USER}/devops-lab2-backend:latest"
                        
                        echo ' Pushing Frontend image...'
                        bat "docker push ${DOCKERHUB_USER}/devops-lab2-frontend:latest"
                        
                        bat 'docker logout'
                    }
                }
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                echo ' Starting deployment...'
                script {
                    bat 'docker-compose down 2>nul || echo "No running containers"'
                    bat 'docker-compose up -d --build'
                    
                    echo 'Deployment completed!'
                    echo ' Frontend: http://localhost:3000'
                    echo '  Backend API: http://localhost:8000'
                }
            }
        }
    }
    
    post {
        always {
            echo ' Cleaning workspace...'
            cleanWs()
        }
        success {
            echo ' Pipeline completed successfully!'
        }
        failure {
            echo ' Pipeline failed'
        }
    }
}