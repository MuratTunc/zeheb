# Base Go image
FROM golang:1.23-alpine AS builder

# Set the app name as a build argument
ARG APP_NAME=mainServiceApp

# Create app directory
RUN mkdir /app

# Copy the app binary to the app directory
COPY ${APP_NAME} /app

# Set the working directory
WORKDIR /app

# Set the command to run the app
CMD [ "/app/${APP_NAME}" ]
