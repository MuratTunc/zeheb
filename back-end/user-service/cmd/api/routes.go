package main

import (
	"net/http"
	"os"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
)

// Define routes for the application
func (app *Config) routes() http.Handler {
	mux := chi.NewRouter()

	// Attach middleware
	app.setupMiddleware(mux)

	// Public routes (no authentication required)
	app.publicRoutes(mux)

	// Protected routes (JWT authentication required)
	mux.Group(func(r chi.Router) {
		r.Use(AuthMiddleware)
		app.protectedRoutes(r)
	})

	return mux
}

// Middleware setup
func (app *Config) setupMiddleware(mux *chi.Mux) {
	// Get allowed origins from environment variable
	corsOrigins := os.Getenv("USER_SERVICE_CORS_ALLOWED_ORIGINS")

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
	mux.Post("/register", app.CreateUserHandler)
	mux.Post("/login", app.LoginUserHandler)
}

// Protected routes (Require JWT authentication)
func (app *Config) protectedRoutes(r chi.Router) {
	r.With(AuthMiddleware).Get("/user", app.GetUserHandler)
	r.With(AuthMiddleware).Post("/update-password", app.UpdatePasswordHandler)
	r.With(AuthMiddleware).Put("/update-user", app.UpdateUserHandler)
	r.With(AuthMiddleware).Put("/deactivate-user", app.DeactivateUserHandler)
	r.With(AuthMiddleware).Put("/activate-user", app.ActivateUserHandler)
	r.With(AuthMiddleware).Put("/update-email", app.UpdateEmailHandler)
	r.With(AuthMiddleware).Put("/update-role", app.UpdateRoleHandler)
	r.With(AuthMiddleware).Delete("/delete-user", app.DeleteUserHandler)
}
