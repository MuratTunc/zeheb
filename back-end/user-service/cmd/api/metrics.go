package main

import (
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// Define metrics
var (
	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"path", "method", "status"},
	)

	httpRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "Duration of HTTP requests",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"path", "method"},
	)
)

// Middleware for collecting metrics
func MetricsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path
		method := r.Method
		start := time.Now()

		// Capture status code
		rr := &responseRecorder{ResponseWriter: w, statusCode: 200}
		next.ServeHTTP(rr, r)

		duration := time.Since(start).Seconds()
		httpRequestsTotal.WithLabelValues(path, method, http.StatusText(rr.statusCode)).Inc()
		httpRequestDuration.WithLabelValues(path, method).Observe(duration)
	})
}

// Helper to record status code
type responseRecorder struct {
	http.ResponseWriter
	statusCode int
}

func (rr *responseRecorder) WriteHeader(code int) {
	rr.statusCode = code
	rr.ResponseWriter.WriteHeader(code)
}
