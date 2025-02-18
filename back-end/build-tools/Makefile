# Environment file and variables
ENV_FILE := .env
WAIT_TIME ?= 5  # Default wait time is 5 seconds, can be overridden
ENVIRONMENT ?= development  # Default to development

build: stop_all_containers clean_volumes check_postgres build_user_service build_mail_service
	@echo "Loading environment variables from .env..."
	@export $(shell sed 's/#.*//g' .env | xargs) && \
	echo "USER_SERVICE_PORT is $$USER_SERVICE_PORT" && \
	echo "USER_SERVICE_NAME is $$USER_SERVICE_NAME" && \
	echo "MAIL_SERVICE_PORT is $$MAIL_SERVICE_PORT" && \
	echo "🚀 Building (when required) and starting docker images with environment variables..." && \
	docker-compose up --build -d && \
	echo "✅ Docker images built and started!" && \
	$(MAKE) wait_for_services && \
	echo "📜 Fetching logs for all services..." && \
	docker-compose logs --tail=20 && \
	echo "🚀 Running Containers:" && \
	docker ps && \
	$(MAKE) wait_for_integration_test && \
	$(MAKE) integration_test



## stop_all_containers: Stops and removes all running Docker containers
stop_all_containers:
	$(MAKE) stop_down_containers

## Selectively build a specific service
build_service:
	@if [ -z "$(SERVICE)" ]; then \
		echo "❌ Please provide a service name. Example: make build_service SERVICE=user-service"; \
		exit 1; \
	fi
	echo "🚀 Building $(SERVICE)..."
	docker-compose build $(SERVICE)
	echo "✅ Done!"

## Selectively build a specific database
build_db:
	@if [ -z "$(DB)" ]; then \
		echo "❌ Please provide a database name. Example: make build_db DB=user-db"; \
		exit 1; \
	fi
	echo "🚀 Building $(DB)..."
	docker-compose build $(DB)
	echo "✅ Done!"

## wait_for_services: Waits for the services to initialize by showing animated dots
wait_for_services:
	echo -n "⏳ Waiting for $(WAIT_TIME) seconds to allow services to initialize "
	for i in $$(seq 1 $(WAIT_TIME)); do \
		echo -n "."; \
		sleep 1; \
	done
	echo " ✅"

## wait_for_integration_test: Waits before running integration tests
wait_for_integration_test:
	echo -n "⏳ Waiting for $(WAIT_TIME) seconds to allow services to be ready "
	for i in $$(seq 1 $(WAIT_TIME)); do \
		echo -n "."; \
		sleep 1; \
	done
	echo " ✅"

## clean_volumes: Removes all volumes (database data) to start fresh
clean_volumes:
	@if [ "$(ENVIRONMENT)" != "production" ]; then \
		echo "🧹 Cleaning up all database volumes..."; \
		docker-compose down -v; \
		echo "✅ All volumes removed!"; \
	else \
		echo "⚠️ Skipping volume cleanup in production environment."; \
	fi

## stop_down_containers: Stops and removes specific or all Docker containers
stop_down_containers:
	@if [ -z "$(CONTAINER)" ]; then \
		echo "🔍 Checking for running containers..."; \
		if [ -n "$$(docker ps -q)" ]; then \
			echo "🛑 Stopping all running Docker containers..."; \
			docker stop $$(docker ps -q); \
			echo "🗑️ Removing all stopped containers..."; \
			docker rm $$(docker ps -aq); \
			echo "✅ All containers stopped and removed."; \
			echo "🛑 Stopping docker-compose..."; \
			docker-compose down; \
			echo "✅ Done!"; \
		else \
			echo "⚡ No running containers found. Skipping stop and remove."; \
		fi \
	else \
		echo "🛑 Stopping container: $(CONTAINER)"; \
		if docker ps --filter "name=$(CONTAINER)" --format "{{.Names}}" | grep -wq "$(CONTAINER)"; then \
			docker stop $(CONTAINER); \
			docker rm $(CONTAINER); \
			echo "✅ Container $(CONTAINER) stopped and removed."; \
		else \
			echo "⚠️ Container $(CONTAINER) not found or already stopped."; \
		fi \
	fi


check_postgres:
	@if sudo lsof -i :5432 | grep LISTEN; then \
		echo "PostgreSQL is running on port 5432. Stopping it..."; \
		sudo systemctl stop postgresql; \
		sleep 2; \
		if sudo lsof -i :5432 | grep LISTEN; then \
			echo "Failed to stop PostgreSQL!"; \
			exit 1; \
		else \
			echo "PostgreSQL stopped successfully!"; \
		fi \
	else \
		echo "PostgreSQL is not running on port 5432."; \
	fi	

## build_user_service: Builds the user-service binary as a Linux executable
build_user_service:
	echo "1- 🚀 Building user-service binary..."
	@set -a; . ./$(ENV_FILE); set +a; \
	cd ../user-service && $$GOFULLPATH build -o $$USER_SERVICE_BINARY ./cmd/api
	echo "✅ Done! user-service binary..."

## build_mail_service: Builds the user-service binary as a Linux executable
build_mail_service:
	echo "1- 🚀 Building mail-service binary..."
	@set -a; . ./$(ENV_FILE); set +a; \
	cd ../mail-service && $$GOFULLPATH build -o $$MAIL_SERVICE_BINARY ./cmd/api
	echo "✅ Done! mail-service binary..."


## logs: Shows logs from all services
logs:
	echo "📜 Fetching last 20 logs for all services..."
	docker-compose logs --tail=20 -f

## help: Displays the list of available commands
help:
	@grep -E '^##' $(MAKEFILE_LIST) | sed -e 's/## //'

## integration_test: Runs integration tests for all services
integration_test:
	echo "🔍 Running integration tests..."
	cd ../integration_tests && \
	./integration_user_service.sh && \
	./integration_mail_service.sh && \
	echo "✅ Integration tests completed successfully!"
