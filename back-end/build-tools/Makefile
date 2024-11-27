MAIN_SERVICE_BINARY=backendServiceApp
LOGGER_SERVICE_BINARY=loggerServiceApp
GOFULLPATH := /usr/local/go/bin/go

## up_build: stops docker-compose (if running), builds all projects and starts docker compose
up_build: build_main_service build_logger_service
	@echo "Stopping docker images (if running...)"
	docker-compose down
	@echo "Building (when required) and starting docker images..."
	docker-compose up --build -d
	@echo "Docker images built and started!"

## down: stop docker compose
down:
	@echo "Stopping docker compose..."
	docker-compose down
	@echo "Done!"

## build_main_service: builds the main_service binary as a linux executable
build_main_service:
	@echo "Building main-service binary..."
	cd ../main-service && env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOFULLPATH) build -o ${MAIN_SERVICE_BINARY} ./cmd/api
	@echo "Done!"

## build_logger_service: builds the logger_service binary as a linux executable
build_logger_service:
	@echo "Building logger-service binary..."
	cd ../logger-service && env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOFULLPATH) build -o ${LOGGER_SERVICE_BINARY} ./cmd/api
	@echo "Done!"	