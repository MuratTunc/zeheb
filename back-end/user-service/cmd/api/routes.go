package main

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Define routes for the application
func (app *Config) routes() http.Handler {
	mux := chi.NewRouter()

	// Attach middleware
	app.SetupMiddleware(mux)

	// Public routes (no authentication required)
	app.publicRoutes(mux)

	// Protected routes (JWT authentication required)
	mux.Group(func(r chi.Router) {
		r.Use(AuthMiddleware)
		app.protectedRoutes(r)
	})

	return mux
}

// Public routes
func (app *Config) publicRoutes(mux *chi.Mux) {
	mux.Get("/health", app.HealthCheckHandler)
	mux.Post("/register", app.CreateUserHandler)
	mux.Post("/login", app.LoginUserHandler)
	mux.Get("/metrics", promhttp.Handler().ServeHTTP)
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
