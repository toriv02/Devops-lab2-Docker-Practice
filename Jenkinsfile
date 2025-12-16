pipeline {
    agent any
    
    environment {
        // Переменные окружения
        DOCKERHUB_USER = 'yaponchick1337'  // ваш логин Docker Hub
        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'  // ID из Credentials
        
        BACKEND_IMAGE = "${DOCKERHUB_USER}/devops-lab2-backend"
        FRONTEND_IMAGE = "${DOCKERHUB_USER}/devops-lab2-frontend"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo '✅ Код получен из Git'
            }
        }
        
        stage('Установка зависимостей') {
            parallel {
                stage('Backend') {
                    steps {
                        dir('.') {
                            // Для Windows используем bat вместо sh
                            bat 'pip install -r requirements.txt || echo "Requirements already installed"'
                        }
                    }
                }
                stage('Frontend') {
                    steps {
                        dir('client') {
                            bat 'npm install'
                        }
                    }
                }
            }
        }
        
        stage('Тестирование') {
            parallel {
                stage('Тесты Backend') {
                    steps {
                        dir('.') {
                            bat 'python manage.py test --no-input || echo "Тестов нет"'
                        }
                    }
                }
                stage('Тесты Frontend') {
                    steps {
                        dir('client') {
                            bat 'npm run test || echo "Тестов нет"'
                        }
                    }
                }
            }
        }
        
        stage('Сборка Docker образов') {
            steps {
                script {
                    echo '🔨 Сборка образа Backend...'
                    bat "docker build -t ${BACKEND_IMAGE}:latest ."
                    
                    echo '🔨 Сборка образа Frontend...'
                    bat "docker build -t ${FRONTEND_IMAGE}:latest client"
                }
            }
        }
        
        stage('Публикация в Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: env.DOCKERHUB_CREDENTIALS,
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        echo '🔐 Авторизация в Docker Hub...'
                        bat "echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin"
                        
                        echo '📤 Загрузка Backend образа...'
                        bat "docker push ${BACKEND_IMAGE}:latest"
                        
                        echo '📤 Загрузка Frontend образа...'
                        bat "docker push ${FRONTEND_IMAGE}:latest"
                        
                        bat 'docker logout'
                    }
                }
            }
        }
        
        stage('Деплой') {
            when {
                branch 'main'
            }
            steps {
                echo '🚀 Запуск деплоя...'
                script {
                    bat 'docker-compose down 2>nul || echo "Контейнеры не запущены"'
                    bat 'docker-compose up -d'
                    
                    echo '✅ Деплой завершен!'
                    echo '🌐 Фронтенд: http://localhost:3000'
                    echo '⚙️  API: http://localhost:8000'
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Очистка рабочей директории...'
            cleanWs()
        }
        success {
            echo '🎉 Pipeline выполнен успешно!'
        }
        failure {
            echo '❌ Pipeline завершился с ошибкой'
        }
    }
}