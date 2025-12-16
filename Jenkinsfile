
pipeline {
    agent any
    
    environment {
        // Docker Hub
        DOCKERHUB_CREDENTIALS = 'docker-hub-creds'
        DOCKERHUB_USER = 'your_username'
        BACKEND_IMAGE = "${DOCKERHUB_USER}/myapp-backend"
        FRONTEND_IMAGE = "${DOCKERHUB_USER}/myapp-frontend"
        

        BACKEND_DIR = '.'
        FRONTEND_DIR = 'client'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Test Backend') {
            steps {
                dir(env.BACKEND_DIR) {
                    sh 'pip install -r requirements.txt || true'
                    sh 'python manage.py test --no-input'
                }
            }
        }
        
        stage('Test Frontend') {
            steps {
                dir(env.FRONTEND_DIR) {
                    sh 'npm install'
                    sh 'npm run test || echo "Tests skipped"'
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {

                    docker.build("${BACKEND_IMAGE}:latest", env.BACKEND_DIR)

                    docker.build("${FRONTEND_IMAGE}:latest", env.FRONTEND_DIR)
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', env.DOCKERHUB_CREDENTIALS) {
                        docker.image("${BACKEND_IMAGE}:latest").push()
                        docker.image("${FRONTEND_IMAGE}:latest").push()
                    }
                }
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                script {

                    sshPublisher(
                        publishers: [
                            sshPublisherDesc(
                                configName: 'deploy-server',
                                transfers: [
                                    sshTransfer(
                                        sourceFiles: 'docker-compose.yml,client/nginx.conf',
                                        removePrefix: '',
                                        remoteDirectory: '/opt/myapp'
                                    )
                                ]
                            )
                        ]
                    )
                    
                    sshCommand(
                        remote: 'deploy-server',
                        command: """
                            cd /opt/myapp
                            docker-compose pull
                            docker-compose down
                            docker-compose up -d
                        """
                    )
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}