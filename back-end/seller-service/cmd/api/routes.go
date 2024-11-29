package main

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
)

func (app *Config) routes() http.Handler {
	mux := chi.NewRouter()

	// CORS Middleware
	mux.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"https://yourdomain.com", "http://yourdomain.com"}, // Update with allowed domains
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	// Middleware for heartbeat (health check)
	mux.Use(middleware.Heartbeat("/ping"))

	// Middleware for error handling
	mux.Use(app.errorHandler)

	// Routes for receiving requests from main service
	mux.Post("/api/v1/seller/receive", app.ReceiveBuyerRequest) // Seller service receives request from main service

	// Routes for submitting price by the seller app
	mux.Post("/api/v1/seller/price", app.SubmitSellerPrice) // Seller app submits price to seller service

	return mux
}

// Generic error handler middleware (optional, but useful for logging and response consistency)
func (app *Config) errorHandler(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				// Log the error
				//app.logger.Printf("Error: %v", err)
				http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}
