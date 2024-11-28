package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/joho/godotenv"
)

type Config struct{}

func main() {

	app := Config{}

	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	ServicePort := os.Getenv("MAIN_SERVICE_PORT")
	ServiceName := os.Getenv("MAIN_SERVICE_NAME")
	if ServicePort == "" {
		ServicePort = "8000" // Default value if not set
	}

	log.Printf("%s is running on port: %s", ServiceName, ServicePort)
	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", ServicePort),
		Handler: app.routes(),
	}

	err = srv.ListenAndServe()
	if err != nil {
		log.Panic(err)
	}
}
