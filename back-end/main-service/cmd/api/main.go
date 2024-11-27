package main

import (
	"log"
	"net/http"
	"os"

	"github.com/joho/godotenv"
)

const serviceName = "THY-FLIGHT-WEB-APPLICATION-BACKEND-SERVICE"

type Config struct{}

func main() {

	app := Config{}

	// Load environment variables from .env file
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	mainServicePort := os.Getenv("MAIN_SERVICE_PORT")
	if mainServicePort == "" {
		mainServicePort = "8000" // Default value if not set
	}

	log.Printf("%s is running on port: %s", serviceName, mainServicePort)

	// Define HTTP server
	srv := &http.Server{
		Addr:    "0.0.0.0" + mainServicePort, // Listen on all network interfaces
		Handler: app.routes(),
	}

	// Start the server
	err = srv.ListenAndServe()
	if err != nil {
		log.Panic(err)
	}
}
