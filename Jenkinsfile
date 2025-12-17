pipeline {
    agent any
    environment {
        // === НАСТРОЙКИ ПУТЕЙ ===
        FRONTEND_ROOT = 'front'
        FRONTEND_APP  = 'front/my-react-app'
        BACKEND_DIR   = 'SimpleApp.Backend'
        
        // === НАСТРОЙКИ DOCKER HUB ===
        DOCKERHUB_CREDENTIALS = 'docker-hub-creds'
        DOCKERHUB_USER = 'yaponchick1337'
        FRONTEND_IMAGE = 'yaponchick1337/simpleapp-frontend'
        BACKEND_IMAGE  = 'yaponchick1337/simpleapp-backend'
        
        // === НАСТРОЙКИ ДЕПЛОЯ ===
        DEPLOY_PATH = 'D:\\DevOps-Deploy\\SimpleApp'
        DEPLOY_CONFIG_NAME = 'docker-compose.yml'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    // Определение измененных файлов на русском
                    def changesRaw = bat(
                        script: 'git diff --name-only HEAD~1 HEAD 2>nul || echo ""',
                        returnStdout: true
                    ).trim()
                    
                    def changedFiles = changesRaw ? changesRaw.split(/\r?\n/).collect { it.trim() }.findAll { it } : []
                    
                    env.CHANGED_FRONTEND = changedFiles.any { it.startsWith("${env.FRONTEND_APP}/") }.toString()
                    env.CHANGED_BACKEND  = changedFiles.any { it.startsWith("${env.BACKEND_DIR}/") }.toString()
                    
                    echo "Frontend изменен: ${env.CHANGED_FRONTEND}, Backend изменен: ${env.CHANGED_BACKEND}"
                }
            }
        }
        
        stage('Install Dependencies and Tests') {
            steps {
                script {
                    if (env.CHANGED_FRONTEND == 'true') {
                        dir(env.FRONTEND_APP) {
                            echo 'Установка зависимостей фронтенда'
                            try { 
                                unstash 'frontend-modules' 
                            } catch (e) { 
                                bat 'npm install --silent'
                                stash name: 'frontend-modules', includes: 'node_modules/**'
                            }
                            echo 'Запуск тестов фронтенда'
                            bat 'npm test -- --watchAll=false --passWithNoTests --silent'
                        }
                    }
                    
                    if (env.CHANGED_BACKEND == 'true') {
                        dir(env.BACKEND_DIR) {
                            echo 'Восстановление зависимостей бэкенда'
                            bat 'dotnet restore --verbosity quiet'
                            echo 'Запуск тестов бэкенда'
                            bat 'dotnet test --no-build --verbosity normal'
                        }
                    }
                }
            }
        }
        
        stage('Build and Push Docker Images') {
            steps {
                script {
                    boolean buildFrontend = env.CHANGED_FRONTEND.toBoolean()
                    boolean buildBackend  = env.CHANGED_BACKEND.toBoolean()
                    
                    if (!buildFrontend && !buildBackend) {
                        echo 'Нет изменений - сборка образов пропущена.'
                        return
                    }
                    
                    withCredentials([usernamePassword(
                        credentialsId: env.DOCKERHUB_CREDENTIALS,
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_TOKEN'
                    )]) {
                        echo "Авторизация в Docker Hub для пользователя ${env.DOCKERHUB_USER}..."
                        bat 'echo %DOCKER_TOKEN% | docker login -u %DOCKER_USER% --password-stdin'
                        
                        // Backend
                        if (buildBackend) {
                            echo "Сборка: ${env.BACKEND_IMAGE}:latest"
                            // ИСПРАВЛЕНИЕ: правильный путь к Dockerfile
                            bat "docker build -t ${env.BACKEND_IMAGE}:latest -f ${env.BACKEND_DIR}/Dockerfile ."
                            echo "Загрузка образа Backend..."
                            bat "docker push ${env.BACKEND_IMAGE}:latest"
                        }
                        
                        // Frontend
                        if (buildFrontend) {
                            echo "Сборка: ${env.FRONTEND_IMAGE}:latest"
                            bat "docker build -t ${env.FRONTEND_IMAGE}:latest -f ${env.FRONTEND_APP}/Dockerfile ${env.FRONTEND_APP}"
                            echo "Загрузка образа Frontend..."
                            bat "docker push ${env.FRONTEND_IMAGE}:latest"
                        }
                        
                        // Logout
                        bat 'docker logout'
                    }
                }
            }
        }
        
        stage('Deploy') {
            when {
                expression {
                    env.GIT_BRANCH == 'origin/main' &&
                    (env.CHANGED_FRONTEND.toBoolean() || env.CHANGED_BACKEND.toBoolean())
                }
            }
            steps {
                script {
                    def sourceFile = "${env.WORKSPACE}\\${env.DEPLOY_CONFIG_NAME}"
                    def destDir = env.DEPLOY_PATH
                    def destConfigFile = "${destDir}\\docker-compose.yml"
                    
                    // 1. Копирование файла
                    powershell """
                        # Проверяем наличие файла в рабочей области
                        if (-not (Test-Path -Path '${sourceFile}')) {
                            Write-Host "ОШИБКА: Исходный файл ${sourceFile} не найден"
                            exit 1
                        }
                        
                        # Создаем папку
                        if (-not (Test-Path -Path '${destDir}')) {
                            New-Item -Path '${destDir}' -ItemType Directory -Force | Out-Null
                        }
                        
                        # Копируем файл
                        Copy-Item -Path '${sourceFile}' -Destination '${destConfigFile}' -Force
                        Write-Host "Файл скопирован: ${sourceFile} -> ${destConfigFile}"
                    """
                    
                    // 2. Деплой
                    bat """
                        cd /d "${destDir}"
                        echo "Текущая директория: %cd%"
                        echo "Проверка docker compose..."
                        docker compose --version
                        
                        echo "Проверка конфигурации..."
                        docker compose -f "docker-compose.yml" -p devops config
                        if errorlevel 1 (
                            echo "ОШИБКА: Неверный YAML файл!"
                            exit 1
                        )
                        
                        echo "Остановка старых контейнеров..."
                        docker compose -f "docker-compose.yml" -p devops down --remove-orphans 2>nul || echo "Контейнеров не было"
                        
                        echo "Загрузка обновленных образов..."
                        docker compose -f "docker-compose.yml" -p devops pull
                        
                        echo "Запуск новых контейнеров..."
                        docker compose -f "docker-compose.yml" -p devops up -d --force-recreate
                        
                        echo "Проверка состояния контейнеров..."
                        docker compose -f "docker-compose.yml" -p devops ps
                    """
                    
                    echo "Деплой завершен:"
                    echo "Фронтенд: http://localhost:3000"
                    echo "Бэкенд: http://localhost:5215"
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline успешно завершен'
        }
        failure {
            echo 'Pipeline завершился с ошибкой'
        }
        always {
            cleanWs()
            bat 'docker logout 2>nul || echo "Docker logout attempted"'
        }
    }
}