package main

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"net/http"
)

// GetBuyerRequestHandler handles incoming buyer requests and sends them to the logger service.
func (app *Config) GetBuyerRequestHandler(w http.ResponseWriter, r *http.Request) {

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		log.Printf("ERROR: Method not allowed %d", http.StatusMethodNotAllowed)
		return
	}

	// Read the request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Failed to read request body", http.StatusInternalServerError)
		log.Printf("ERROR: Failed to read request body: %v", err)
		return
	}
	defer r.Body.Close()

	// Send the request body to the logger service
	loggerURL := "http://logger-service:8001/log"
	err = sendTextToLogger(loggerURL, body)
	if err != nil {
		http.Error(w, "Failed to log the request", http.StatusInternalServerError)
		log.Printf("ERROR: %v", err)
		return
	}

	// Success response
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Request logged successfully"))
	log.Println("INFO: Request logged successfully")
}

// sendTextToLogger sends a POST request with the given text to the logger service.
func sendTextToLogger(url string, text []byte) error {
	resp, err := http.Post(url, "application/json", bytes.NewReader(text))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// Check the response status code
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("logger service returned status %d", resp.StatusCode)
	}

	return nil
}
