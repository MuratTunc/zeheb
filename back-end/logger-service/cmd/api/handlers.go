package main

import (
	"io"
	"log"
	"net/http"
)

// Log handles incoming requests, modifies the payload, and sends a response
func (app *Config) Log(w http.ResponseWriter, r *http.Request) {
	// Read the request body from the main service
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Failed to read request body", http.StatusInternalServerError)
		log.Printf("ERROR: Failed to read request body: %v", err)
		return
	}
	defer r.Body.Close()

	// Append "Hello" to the received text
	updatedText := string(body) + " Hello"

	// Prepare the response payload
	payload := jsonResponse{
		Error:   false,
		Message: "Message from logger service",
		Data:    updatedText,
	}

	// Write the JSON response
	err = app.writeJSON(w, http.StatusAccepted, payload)
	if err != nil {
		log.Printf("ERROR: Failed to write JSON response: %v", err)
		http.Error(w, "Failed to write response", http.StatusInternalServerError)
	}
}
