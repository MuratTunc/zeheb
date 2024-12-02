BUYER_SERVICE_BINARY=buyerServiceApp
SELLER_SERVICE_BINARY=sellerServiceApp
GOFULLPATH := /usr/local/go/bin/go  # Use static path for Go binary

## debug: prints the resolved Go binary path
debug:
	@echo "GOFULLPATH is set to: $(GOFULLPATH)"

## up_build: stops docker-compose (if running), builds all projects, and starts docker compose
up_build: clean build_buyer_service build_seller_service
	@echo "Stopping docker images (if running...)"
	docker-compose down
	@echo "Building (when required) and starting docker images with environment variables..."
	docker-compose up --build -d
	@echo "Docker images built and started!"

## down: stop docker compose
down:
	@echo "Stopping docker compose..."
	docker-compose down
	@echo "Done!"

## clean: removes built binaries
clean:
	@echo "Cleaning up built binaries..."
	rm -f ../buyer-service/$(BUYER_SERVICE_BINARY)
	rm -f ../seller-service/$(SELLER_SERVICE_BINARY)
	@echo "Done!"

## build_buyer_service: builds the buyer-service binary as a linux executable
build_buyer_service:
	@echo "Building buyer-service binary..."
	cd ../buyer-service && env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOFULLPATH) build -o $(BUYER_SERVICE_BINARY) ./cmd/api
	@echo "Done!"

## build_seller_service: builds the seller-service binary as a linux executable
build_seller_service:
	@echo "Building seller-service binary..."
	cd ../seller-service && env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOFULLPATH) build -o $(SELLER_SERVICE_BINARY) ./cmd/api
	@echo "Done!"

## logs: shows logs from all services
logs:
	@echo "Fetching logs for all services..."
	docker-compose logs -f

## help: displays the list of available commands
help:
	@grep -E '^##' $(MAKEFILE_LIST) | sed -e 's/## //'
