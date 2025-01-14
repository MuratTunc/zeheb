package main

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/go-chi/httprate"
)

func (app *Config) routes() http.Handler {
	mux := chi.NewRouter()

	// CORS configuration
	allowedOrigins := []string{
		"https://zeheb.com",
		"https://www.zeheb.com",
		"http://localhost:3000",
	}

	mux.Use(cors.Handler(cors.Options{
		AllowedOrigins:   allowedOrigins,
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	// Middleware
	mux.Use(middleware.Heartbeat("/ping"))
	mux.Use(middleware.Recoverer)
	mux.Use(middleware.Logger)
	mux.Use(httprate.LimitByIP(100, 1*time.Minute))

	// Custom error handlers
	mux.NotFound(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		http.Error(w, `{"error": "Resource not found"}`, http.StatusNotFound)
	})

	mux.MethodNotAllowed(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		http.Error(w, `{"error": "Method not allowed"}`, http.StatusMethodNotAllowed)
	})

	// API Routes
	mux.Route("/api/v1", func(r chi.Router) {
		r.Get("/scraping/goldprice", app.ScrapeGoldPriceHandler) // Add GET method
	})

	return mux
}
