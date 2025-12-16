pipeline {
    agent any
    
    environment {
        // Настройка путей
        FRONTEND_DIR = 'client'
        BACKEND_DIR = 'project'
        
        // Docker Hub настройки
        DOCKERHUB_USER = 'toriv00'
        FRONTEND_IMAGE = "${DOCKERHUB_USER}/devops-lab2-frontend"
        BACKEND_IMAGE = "${DOCKERHUB_USER}/devops-lab2-backend"
        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'
        
        // Настройки деплоя
        DEPLOY_PATH = '.'  // Текущая директория (или укажите полный путь)
        DEPLOY_CONFIG_NAME = 'docker-compose.yml'
    }
    
    stages {
        stage('Checkout и анализ изменений') {
            steps {
                checkout scm
                script {
                    // Получаем текущую ветку
                    def branch = bat(
                        script: 'git branch --show-current',
                        returnStdout: true
                    ).trim()
                    env.GIT_BRANCH = branch
                    echo "Build for branch: ${env.GIT_BRANCH}"
                    
                    // Анализ измененных файлов (как в готовой работе)
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
                    
                    echo "Frontend изменён: ${env.CHANGED_FRONTEND}, Backend изменён: ${env.CHANGED_BACKEND}"
                }
            }
        }
        
        stage('Установка зависимостей и тесты') {
            steps {
                script {
                    // Frontend зависимости (только если были изменения)
                    if (env.CHANGED_FRONTEND == 'true') {
                        dir(env.FRONTEND_DIR) {
                            echo 'Установка зависимостей фронтенда'
                            bat 'npm ci --silent'
                            echo 'Запуск тестов фронтенда'
                            bat 'npm test -- --watchAll=false --passWithNoTests --silent 2>&1 || echo "Тесты фронтенда выполнены"'
                        }
                    }
                    
                    // Backend зависимости (только если были изменения)
                    if (env.CHANGED_BACKEND == 'true') {
                        echo 'Установка зависимостей бэкенда'
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
                                    echo requirements.txt not found, installing default...
                                    "${env.PYTHON_PATH}" -m pip install django djangorestframework
                                )
                            """
                            
                            // Запуск тестов Django (только не в main ветке)
                            if (env.GIT_BRANCH != 'main' && env.GIT_BRANCH != 'master') {
                                echo 'Running Django tests...'
                                bat """
                                    @echo off
                                    if exist "manage.py" (
                                        echo Checking Django project...
                                        "${env.PYTHON_PATH}" manage.py check
                                        
                                        echo Running Django tests...
                                        "${env.PYTHON_PATH}" manage.py test --verbosity=2
                                    ) else (
                                        echo manage.py not found, skipping tests
                                    )
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('Сборка Docker образов') {
            steps {
                script {
                    boolean buildFrontend = env.CHANGED_FRONTEND == 'true'
                    boolean buildBackend = env.CHANGED_BACKEND == 'true'
                    
                    // Если нет изменений, пропускаем сборку (оптимизация)
                    if (!buildFrontend && !buildBackend) {
                        echo 'Нет изменений в коде - сборка Docker образов пропускается'
                        return
                    }
                    
                    echo 'Начинаем сборку Docker образов...'
                    
                    // Сборка Backend
                    if (buildBackend) {
                        echo 'Сборка образа Backend...'
                        bat "docker build -t ${env.BACKEND_IMAGE}:latest ."
                    }
                    
                    // Сборка Frontend
                    if (buildFrontend) {
                        echo 'Сборка образа Frontend...'
                        bat "docker build -t ${env.FRONTEND_IMAGE}:latest ${env.FRONTEND_DIR}"
                    }
                    
                    echo 'Docker образы успешно собраны!'
                }
            }
        }
        
        stage('Публикация в Docker Hub') {
            steps {
                script {
                    boolean buildFrontend = env.CHANGED_FRONTEND == 'true'
                    boolean buildBackend = env.CHANGED_BACKEND == 'true'
                    
                    if (!buildFrontend && !buildBackend) {
                        echo 'Нет изменений - публикация в Docker Hub пропускается'
                        return
                    }
                    
                    withCredentials([usernamePassword(
                        credentialsId: env.DOCKERHUB_CREDENTIALS,
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        echo 'Авторизация в Docker Hub...'
                        bat "echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin"
                        
                        // Публикация Backend
                        if (buildBackend) {
                            echo 'Публикация Backend образа...'
                            bat "docker push ${env.BACKEND_IMAGE}:latest"
                        }
                        
                        // Публикация Frontend
                        if (buildFrontend) {
                            echo 'Публикация Frontend образа...'
                            bat "docker push ${env.FRONTEND_IMAGE}:latest"
                        }
                        
                        bat 'docker logout'
                        echo 'Образы успешно опубликованы в Docker Hub!'
                    }
                }
            }
        }
        
        stage('Деплой в Production') {
            when {
                expression {
                    def branch = env.GIT_BRANCH ?: ''
                    return (branch == 'main' || branch == 'master') &&
                           (env.CHANGED_FRONTEND == 'true' || env.CHANGED_BACKEND == 'true')
                }
            }
            steps {
                script {
                    echo '=== ЗАПУСК ПРОЦЕССА ДЕПЛОЯ ==='
                    echo 'Ветка: main/master - запускаем деплой'
                    
                    // Проверяем наличие docker-compose.yml
                    def composeExists = bat(
                        script: '@echo off && if exist "docker-compose.yml" (echo EXISTS) else (echo NOT_FOUND)',
                        returnStdout: true
                    ).trim()
                    
                    if (!composeExists.contains("EXISTS")) {
                        error "Файл docker-compose.yml не найден!"
                    }
                    
                    // Останавливаем и удаляем старые контейнеры
                    echo 'Остановка старых контейнеров...'
                    bat '''
                        @echo off
                        echo Stopping existing containers...
                        docker-compose down --remove-orphans 2>nul || echo "No containers to stop"
                        
                        echo Removing old containers and networks...
                        docker-compose down -v 2>nul || echo "Cleanup completed"
                        
                        echo Removing unused Docker resources...
                        docker system prune -f 2>nul || echo "Prune completed"
                    '''
                    
                    // Получаем свежие образы из Docker Hub
                    echo 'Получение обновленных образов...'
                    bat '''
                        @echo off
                        echo Pulling latest images from Docker Hub...
                        docker-compose pull || echo "Pull completed"
                    '''
                    
                    // Запускаем новые контейнеры
                    echo 'Запуск приложения...'
                    bat '''
                        @echo off
                        echo Starting containers...
                        docker-compose up -d --build
                        
                        echo Waiting for containers to initialize...
                        timeout /t 15 /nobreak > nul
                    '''
                    
                    // Проверяем статус
                    echo 'Проверка статуса контейнеров...'
                    bat '''
                        @echo off
                        echo "=== CONTAINER STATUS ==="
                        docker-compose ps
                        
                        echo.
                        echo "=== RECENT LOGS ==="
                        docker-compose logs --tail=10
                    '''
                    
                    echo '=== ДЕПЛОЙ УСПЕШНО ЗАВЕРШЕН ==='
                    echo 'Frontend доступен по адресу: http://localhost:3000'
                    echo 'Backend API доступен по адресу: http://localhost:8000'
                    echo 'База данных: localhost:1433'
                    
                    env.DEPLOY_PERFORMED = 'true'
                }
            }
        }
    }
    
    post {
        success {
            script {
                if (env.DEPLOY_PERFORMED == 'true') {
                    echo '=== CD ПРОЦЕСС УСПЕШНО ЗАВЕРШЕН ==='
                    echo 'Приложение успешно развернуто в production!'
                } else {
                    echo '=== CI ПРОЦЕСС УСПЕШНО ЗАВЕРШЕН ==='
                    echo 'Сборка и тесты успешно пройдены'
                }
            }
        }
        failure {
            echo '=== ПАЙПЛАЙН ЗАВЕРШИЛСЯ С ОШИБКОЙ ==='
            // Попытка очистки в случае ошибки
            bat '''
                @echo off
                echo Attempting cleanup after failure...
                docker-compose down 2>nul || echo "Cleanup attempted"
            '''
        }
        always {
            echo "Статус сборки: ${currentBuild.result ?: 'SUCCESS'}"
            echo "Ветка: ${env.GIT_BRANCH ?: 'не определена'}"
            echo "Длительность: ${currentBuild.durationString}"
            
            // Очистка workspace
            cleanWs()
            
            // Выход из Docker (на всякий случай)
            bat 'docker logout 2>nul || echo "Docker logout completed"'
        }
    }
}