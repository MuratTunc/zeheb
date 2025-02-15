# Use Golang image to build the binary
FROM golang:1.23-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy Go module files first for caching dependencies
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the Go source code (this assumes the source code is inside ./cmd/api)
COPY cmd/api /app/cmd/api

# Build the Go application as a static binary
RUN go build -o userServiceApp ./cmd/api

# Final lightweight image
FROM alpine:latest

# Set working directory for the final image
WORKDIR /app

# Copy the compiled binary from the builder stage
COPY --from=builder /app/userServiceApp .

# Run the binary
CMD ["/app/userServiceApp"]
