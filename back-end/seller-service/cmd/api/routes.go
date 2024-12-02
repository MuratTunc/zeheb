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

	// Middleware
	mux.Use(middleware.Heartbeat("/ping")) // Health check endpoint
	mux.Use(middleware.Recoverer)          // Recover from panics gracefully
	mux.Use(middleware.Logger)             // Log all requests

	// Routes for receiving requests from BUYER SERVICE
	mux.Post("/api/v1/seller/receive", app.ReceiveBuyerRequest) // Seller service receives request from buyer service

	// Routes for submitting price by the SELLER APP
	mux.Post("/api/v1/seller/price", app.SubmitSellerPrice) // SELLER APP submits price to seller service

	return mux
}
