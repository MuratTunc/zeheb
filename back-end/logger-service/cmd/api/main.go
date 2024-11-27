package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

const serviceName = "LOGGER-SERVICE"

type Config struct{}

func main() {

	app := Config{}

	loggerServicePort := os.Getenv("LOGGER_SERVICE_PORT")
	if loggerServicePort == "" {
		loggerServicePort = "8001" // Default value if not set
	}

	// start web server
	// go app.serve()
	log.Printf("%s is running on port: %s", serviceName, loggerServicePort)
	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", loggerServicePort),
		Handler: app.routes(),
	}

	err := srv.ListenAndServe()
	if err != nil {
		log.Panic()
	}

}
