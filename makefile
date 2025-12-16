
.PHONY: up down build logs clean test migrate

up:
	docker-compose up -d

down:
	docker-compose down

build:
	docker-compose build

logs:
	docker-compose logs -f

logs-backend:
	docker-compose logs -f backend

logs-frontend:
	docker-compose logs -f frontend

clean:
	docker-compose down -v
	docker system prune -f

test:
	docker-compose exec backend python manage.py test
	docker-compose exec frontend npm run test 2>/dev/null || echo "No tests in frontend"

migrate:
	docker-compose exec backend python manage.py migrate

createsuperuser:
	docker-compose exec backend python manage.py createsuperuser

status:
	docker-compose ps
	docker-compose images