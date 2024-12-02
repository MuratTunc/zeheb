package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"time"

	_ "github.com/lib/pq" // Import the pq package for PostgreSQL
)

// Config holds configuration values, including database connections.
type Config struct {
	DB *sql.DB // Database connection
}

// BuyerRequest represents the structure of the buyer's request.
type BuyerRequest struct {
	BuyerID     string `json:"buyer_id"`
	RequestText string `json:"request_text"`
	Timestamp   string `json:"timestamp"`
}

// BuyerResponse represents the structure of the response to the buyer.
type BuyerResponse struct {
	Status    string `json:"status"`
	Message   string `json:"message"`
	RequestID string `json:"request_id"`
}

// GetBuyerRequestHandler handles incoming buyer requests, stores them in the database, and sends them to the seller service.
func (app *Config) GetBuyerRequestHandler(w http.ResponseWriter, r *http.Request) {
	log.Printf("GetBuyerRequestHandler-----")
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
		return
	}

	// Parse the incoming JSON request
	var buyerRequest BuyerRequest
	err := json.NewDecoder(r.Body).Decode(&buyerRequest)
	if err != nil {
		http.Error(w, "Invalid JSON payload", http.StatusBadRequest)
		return
	}
	/*
		// Add a timestamp if it's not provided
		if buyerRequest.Timestamp == "" {
			buyerRequest.Timestamp = time.Now().UTC().Format(time.RFC3339)
		}

		// Save the buyer request in the database
		requestID, err := app.saveBuyerRequest(buyerRequest)
		if err != nil {
			log.Printf("Error saving buyer request to database: %v", err)
			http.Error(w, "Failed to save your request", http.StatusInternalServerError)
			return
		}

		// Forward the request to the seller service
		buyerRequestJSON, _ := json.Marshal(buyerRequest)
		sellerServiceURL := "http://seller-service:8080/process-request" // Replace with your actual seller service URL
		_, err = sendBuyerRequestsToSellerService(sellerServiceURL, buyerRequestJSON)
		if err != nil {
			log.Printf("Error forwarding request to seller service: %v", err)
			http.Error(w, "Failed to process your request", http.StatusInternalServerError)
			return
		}
	*/
	// Respond to the buyer
	buyerResponse := BuyerResponse{
		Status:    "success",
		Message:   "Your request has been received and forwarded to sellers.",
		RequestID: "123",
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(buyerResponse)
}

// sendBuyerRequestsToSellerService forwards buyer requests to the seller service.
func sendBuyerRequestsToSellerService(url string, text []byte) (string, error) {
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(text))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := ioutil.ReadAll(resp.Body)
		return "", fmt.Errorf("seller service returned status %d: %s", resp.StatusCode, string(body))
	}

	// Read and parse the response from the seller service
	var response map[string]interface{}
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	err = json.Unmarshal(body, &response)
	if err != nil {
		return "", err
	}

	// Assume the seller service response includes a "request_id"
	requestID, ok := response["request_id"].(string)
	if !ok {
		return "", fmt.Errorf("invalid response from seller service")
	}

	return requestID, nil
}

// saveBuyerRequest saves the buyer request into the database.
func (app *Config) saveBuyerRequest(request BuyerRequest) (string, error) {
	// Prepare the SQL statement for inserting the buyer request into the database
	sqlStatement := `
		INSERT INTO buyer_requests (buyer_id, request_text, timestamp)
		VALUES ($1, $2, $3) RETURNING request_id`
	var requestID string
	err := app.DB.QueryRow(sqlStatement, request.BuyerID, request.RequestText, request.Timestamp).Scan(&requestID)
	if err != nil {
		log.Printf("Error saving buyer request to database: %v", err)
		return "", err
	}

	return requestID, nil
}

// GetSellerPriceHandler handles the seller's price response and saves it to the database.
func (app *Config) GetSellerPriceHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
		return
	}

	// Parse the incoming JSON request
	var sellerPriceResponse struct {
		SellerID  string `json:"seller_id"`
		RequestID string `json:"request_id"`
		Price     string `json:"price"`
		Timestamp string `json:"timestamp"`
	}
	err := json.NewDecoder(r.Body).Decode(&sellerPriceResponse)
	if err != nil {
		http.Error(w, "Invalid JSON payload", http.StatusBadRequest)
		return
	}

	// Logic to save seller's price to the database
	err = app.saveSellerPrice(sellerPriceResponse)
	if err != nil {
		http.Error(w, "Failed to save price", http.StatusInternalServerError)
		return
	}

	// Respond with success
	response := struct {
		Status  string `json:"status"`
		Message string `json:"message"`
	}{
		Status:  "success",
		Message: "Price response received and saved successfully.",
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// saveSellerPrice stores the seller's price in the database.
func (app *Config) saveSellerPrice(priceResponse struct {
	SellerID  string `json:"seller_id"`
	RequestID string `json:"request_id"`
	Price     string `json:"price"`
	Timestamp string `json:"timestamp"`
}) error {
	// Insert the seller's price into the database
	sqlStatement := `
		INSERT INTO seller_prices (seller_id, request_id, price, timestamp)
		VALUES ($1, $2, $3, $4)`
	_, err := app.DB.Exec(sqlStatement, priceResponse.SellerID, priceResponse.RequestID, priceResponse.Price, priceResponse.Timestamp)
	if err != nil {
		log.Printf("Error saving seller price to database: %v", err)
		return err
	}
	return nil
}
