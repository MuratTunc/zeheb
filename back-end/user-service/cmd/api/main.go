package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {

	PrintEnvVariables()

	// Ensure DB connection before starting the server
	db, err := connectToDB()

	if err != nil {
		log.Fatalf("❌ Database connection failed : %v", err)
	}

	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", ServicePort),
		Handler: (&Config{DB: db}).routes(), // Pass db to routes
	}

	err = srv.ListenAndServe()
	if err != nil {
		log.Fatalf("❌ Server failed to start : %v", err)
	}

	fmt.Printf("🚀 %s is running on port: %s\n", ServiceName, ServicePort)
}
