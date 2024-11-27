package main

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
)

func (app *Config) routes() http.Handler {
	mux := chi.NewRouter()

	// CORS configuration to allow your domain and local development environment
	mux.Use(cors.Handler(cors.Options{
		AllowedOrigins: []string{
			"https://thyflightmenuassistant.com",     // Allow requests from your production domain
			"https://www.thyflightmenuassistant.com", // Allow www version of your domain
			"http://localhost:3000",                  // Allow requests from localhost (your local dev environment)
		},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},                 // Methods allowed
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"}, // Allowed headers
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300, // Cache preflight response for 5 minutes
	}))

	// Middleware for heartbeat (health check)
	mux.Use(middleware.Heartbeat("/ping"))

	// Define application-specific routes

	mux.Post("/getorder", app.GetBuyerRequest)

	return mux
}
