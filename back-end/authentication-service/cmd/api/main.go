package main

import (
	"authentication-service/data"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

type Config struct {
	DB     *sql.DB
	Models data.Models
}

var counts int64

func main() {

	// connect to DB
	conn := connectToDB()
	if conn == nil {
		log.Panic("Can't connect to Postgres!")
	}

	// set up config
	var app = Config{
		DB:     conn,
		Models: data.New(conn),
	}

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

	err := srv.ListenAndServe()
	if err != nil {
		log.Panic()
	}
}

func openDB(dsn string) (*sql.DB, error) {
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		return nil, err
	}

	err = db.Ping()
	if err != nil {
		return nil, err
	}

	return db, nil
}

func connectToDB() *sql.DB {
	dsn := os.Getenv("DSN")

	for {
		connection, err := openDB(dsn)
		if err != nil {
			log.Println("Postgres not yet ready ...")
			counts++
		} else {
			log.Println("Connected to Postgres!")
			return connection
		}

		if counts > 10 {
			log.Println(err)
			return nil
		}

		log.Println("Backing off for two seconds....")
		time.Sleep(2 * time.Second)
		continue
	}
}
