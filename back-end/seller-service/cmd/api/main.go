// Seller Service: Manages responses from the Seller app.
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {

	app := Config{}

	ServicePort := os.Getenv("SELLER_SERVICE_PORT")
	ServiceName := os.Getenv("SELLER_SERVICE_NAME")

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
