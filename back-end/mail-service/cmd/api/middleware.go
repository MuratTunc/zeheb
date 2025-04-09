package main

import (
	"net/http"
	"os"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
)

// SetupMiddleware sets up all global middleware
func (app *Config) SetupMiddleware(mux *chi.Mux) {
	mux.Use(app.CORSMiddleware())
	mux.Use(middleware.Heartbeat("/ping"))
	mux.Use(middleware.Recoverer)
	mux.Use(MetricsMiddleware)
	mux.Use(middleware.Logger)

}

// CORSMiddleware returns a cors.Handler middleware
func (app *Config) CORSMiddleware() func(http.Handler) http.Handler {
	corsOrigins := os.Getenv("USER_SERVICE_CORS_ALLOWED_ORIGINS")
	allowedOrigins := strings.Split(corsOrigins, ",")

	return cors.Handler(cors.Options{
		AllowedOrigins:   allowedOrigins,
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300,
	})
}
