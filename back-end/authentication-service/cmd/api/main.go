package main

import (
	"authentication-service/data"
	"database/sql"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
)

type Config struct {
	DSN    string
	Domain string
	DB     *sql.DB
	Models data.Models
}

func main() {
	// set application config
	var app Config

	// read from command line
	flag.StringVar(&app.DSN, "dsn", "host=localhost port=5432 user=postgres password=postgres dbname=movies sslmode=disable timezone=UTC connect_timeout=5", "Postgres connection string")
	flag.Parse()

	// connect to the database
	conn, err := app.connectToDB()
	if err != nil {
		log.Fatal(err)
	}
	app.DB = conn
	defer app.DB.Close()

	app.Domain = "example.com"

	ServicePort := os.Getenv("AUTHENTICATION_SERVICE_PORT")
	ServiceName := os.Getenv("AUTHENTICATION_SERVICE_NAME")

	if ServicePort == "" || ServiceName == "" {
		log.Fatal("Error: Service environment variables are not set")
	}

	log.Printf("%s is running on port: %s", ServiceName, ServicePort)
	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", ServicePort),
		Handler: app.routes(),
	}

	err = srv.ListenAndServe()
	if err != nil {
		log.Panic()
	}
}
