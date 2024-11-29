package main

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
)

func (app *Config) routes() http.Handler {
	mux := chi.NewRouter()

	// CORS configuration to allow domain and local development environment
	allowedOrigins := []string{
		"https://zeheb.com",     // Allow requests from your production domain
		"https://www.zeheb.com", // Allow www version of domain
		"http://localhost:3000", // Allow requests from localhost (your local dev environment)
	}

	mux.Use(cors.Handler(cors.Options{
		AllowedOrigins:   allowedOrigins,
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300, // Cache preflight response for 5 minutes
	}))

	// Middleware
	mux.Use(middleware.Heartbeat("/ping")) // Health check endpoint
	mux.Use(middleware.Recoverer)          // Recover from panics gracefully
	mux.Use(middleware.Logger)             // Log all requests

	// API Routes
	mux.Route("/api/v1", func(r chi.Router) {
		// Existing route for buyer's price request
		r.Post("/buyer/giveprice", app.GetBuyerRequestHandler)

		// New route for seller's price response
		r.Post("/seller/price", app.GetSellerPriceHandler) // Example new handler
	})
	return mux
}
