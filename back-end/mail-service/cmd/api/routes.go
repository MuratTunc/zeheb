package main

import (
	"net/http"
	"os"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Define routes for the application
func (app *Config) routes() http.Handler {

	mux := chi.NewRouter()

	app.SetupMiddleware(mux)

	app.publicRoutes(mux) // Public routes (no authentication required)

	return mux
}

// Middleware setup
func (app *Config) setupMiddleware(mux *chi.Mux) {
	// Get allowed origins from environment variable
	corsOrigins := os.Getenv("MAIL_SERVICE_CORS_ALLOWED_ORIGINS")

	// Split the CORS origins by comma
	allowedOrigins := strings.Split(corsOrigins, ",")

	mux.Use(cors.Handler(cors.Options{
		AllowedOrigins:   allowedOrigins,
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	// Standard middleware
	mux.Use(middleware.Heartbeat("/ping")) // Health check route
	mux.Use(middleware.Recoverer)          // Panic recovery
	mux.Use(middleware.Logger)             // Logs all HTTP requests
}

// Public routes
func (app *Config) publicRoutes(mux *chi.Mux) {
	mux.Get("/health", app.HealthCheckHandler)
	mux.Post("/send-auth-code-mail", app.GenerateAndSendAuthCode)
	mux.Delete("/delete-mail", app.DeleteMailHandler)
	mux.Post("/signin", app.SigninHandler)
	mux.Get("/metrics", promhttp.Handler().ServeHTTP)
}
