# Base Go image
FROM golang:1.23-alpine AS builder

# Create the application directory
RUN mkdir /app

# Copy the compiled binary into the container
COPY authenticationServiceApp /app

# Set the working directory
WORKDIR /app

# Command to run the authentication service
CMD ["/app/authenticationServiceApp"]
