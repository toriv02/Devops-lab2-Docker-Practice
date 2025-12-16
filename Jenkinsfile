pipeline {
    agent any
    
    environment {
        DOCKERHUB_USER = 'yaponchick1337'
        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'
        
        BACKEND_IMAGE = "${DOCKERHUB_USER}/devops-lab2-backend"
        FRONTEND_IMAGE = "${DOCKERHUB_USER}/devops-lab2-frontend"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo '✅ Code downloaded from Git'
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    echo '🔨 Building Backend image...'
                    bat "docker build -t ${BACKEND_IMAGE}:latest ."
                    
                    echo '🔨 Building Frontend image...'
                    bat "docker build -t ${FRONTEND_IMAGE}:latest client"
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: env.DOCKERHUB_CREDENTIALS,
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        echo '🔐 Logging into Docker Hub...'
                        bat "echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin"
                        
                        echo '📤 Pushing Backend image...'
                        bat "docker push ${BACKEND_IMAGE}:latest"
                        
                        echo '📤 Pushing Frontend image...'
                        bat "docker push ${FRONTEND_IMAGE}:latest"
                        
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
                echo '🚀 Starting deployment...'
                script {
                    bat 'docker-compose down 2>nul || echo "No running containers"'
                    bat 'docker-compose up -d --build'
                    
                    echo '✅ Deployment completed!'
                    echo '🌐 Frontend: http://localhost:3000'
                    echo '⚙️  Backend API: http://localhost:8000'
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning workspace...'
            cleanWs()
        }
        success {
            echo '🎉 Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed'
        }
    }
}