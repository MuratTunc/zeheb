package main

import (
	"fmt"
	"log"
	"os"
)

// Load environment variables
var (
	DBHost      = os.Getenv("USER_POSTGRES_DB_HOST")
	DBUser      = os.Getenv("USER_POSTGRES_DB_USER")
	DBPassword  = os.Getenv("USER_POSTGRES_DB_PASSWORD")
	DBName      = os.Getenv("USER_POSTGRES_DB_NAME")
	ServicePort = os.Getenv("USER_SERVICE_PORT")
	ServiceName = os.Getenv("USER_SERVICE_NAME")
	JWTSecret   = os.Getenv("USER_SERVICE_JWT_SECRET")
)

// Set DBPort explicitly to 5432 inside the container
const DBPort = "5432"

// PrintEnvVariables prints all environment variables for debugging
func PrintEnvVariables() {
	fmt.Println("🔧 Loaded Environment Variables - USER_SERVICE")
	fmt.Printf("DBHost: %s\n", DBHost)
	fmt.Printf("DBUser: %s\n", DBUser)
	fmt.Printf("DBPassword: %s\n", DBPassword)
	fmt.Printf("DBName: %s\n", DBName)
	fmt.Printf("DBPort: %s\n", DBPort)
	fmt.Printf("ServicePort: %s\n", ServicePort)
	fmt.Printf("ServiceName: %s\n", ServiceName)
	fmt.Printf("JWTSecret: %s\n", JWTSecret)

	// Ensure all required environment variables are set
	missingEnvVars := false
	if DBHost == "" || DBUser == "" || DBPassword == "" || DBName == "" {
		fmt.Println("❌ Error: Missing required database environment variables")
		missingEnvVars = true
	}
	if ServicePort == "" || ServiceName == "" {
		fmt.Println("❌ Error: Missing required service environment variables")
		missingEnvVars = true
	}

	if missingEnvVars {
		log.Fatal("❌ Exiting due to missing environment variables.")
	}
}
