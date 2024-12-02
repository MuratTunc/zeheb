package main

import (
	"encoding/json"
	"log"
	"net/http"
)

type Config struct{}

// ReceiveBuyerRequest handles the POST request when the main service sends a buyer request to the seller service.
func (app *Config) ReceiveBuyerRequest(w http.ResponseWriter, r *http.Request) {
	var request BuyerRequest

	// Decode the JSON request body into the BuyerRequest struct
	err := json.NewDecoder(r.Body).Decode(&request)
	if err != nil {
		http.Error(w, "Unable to parse request body", http.StatusBadRequest)
		return
	}

	// Store the buyer request in the seller service's database
	err = storeBuyerRequestInDB(request)
	if err != nil {
		http.Error(w, "Error storing buyer request", http.StatusInternalServerError)
		return
	}

	// Respond with a success message
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "Request received successfully"})
}

// SubmitSellerPrice handles the POST request when the seller app submits a price for the buyer's request.
func (app *Config) SubmitSellerPrice(w http.ResponseWriter, r *http.Request) {
	var priceSubmission PriceSubmission

	// Decode the JSON request body into the PriceSubmission struct
	err := json.NewDecoder(r.Body).Decode(&priceSubmission)
	if err != nil {
		http.Error(w, "Unable to parse price submission", http.StatusBadRequest)
		return
	}

	// Store the price in the seller service's database
	err = storePriceInDB(priceSubmission)
	if err != nil {
		http.Error(w, "Error storing seller price", http.StatusInternalServerError)
		return
	}

	// Optionally, send the price back to the main service
	err = sendPriceToMainService(priceSubmission)
	if err != nil {
		http.Error(w, "Error sending price to main service", http.StatusInternalServerError)
		return
	}

	// Respond with a success message
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "Price submitted successfully"})
}

// storeBuyerRequestInDB stores the buyer request in the seller service's database.
// This is a placeholder function, implement your actual DB logic here.
func storeBuyerRequestInDB(request BuyerRequest) error {
	// Database logic to store the buyer request
	// Example: db.Save(&request)
	log.Printf("Stored buyer request: %+v", request)

	// Pseudo code for database insertion
	// err := db.Exec("INSERT INTO buyer_requests (buyer_id, item_details) VALUES (?, ?)", request.BuyerID, request.ItemDetails)
	// if err != nil {
	//     return err
	// }

	return nil
}

// storePriceInDB stores the seller's price in the database.
func storePriceInDB(priceSubmission PriceSubmission) error {
	// Database logic to store the price
	// Example: db.Save(&priceSubmission)
	log.Printf("Stored price: %+v", priceSubmission)

	// Pseudo code for database insertion
	// err := db.Exec("INSERT INTO seller_prices (seller_id, buyer_id, price) VALUES (?, ?, ?)", priceSubmission.SellerID, priceSubmission.BuyerID, priceSubmission.Price)
	// if err != nil {
	//     return err
	// }

	return nil
}

// sendPriceToMainService sends the seller's price to the main service.
func sendPriceToMainService(priceSubmission PriceSubmission) error {
	// Logic to send the price back to the main service
	// Example: Make an HTTP POST request to the main service
	log.Printf("Sending price to main service: %+v", priceSubmission)

	// Pseudo code for sending the price to the main service
	// req, err := http.NewRequest("POST", "http://main-service:8080/submit-price", bytes.NewBuffer(priceJSON))
	// if err != nil {
	//     return err
	// }
	// client := &http.Client{}
	// resp, err := client.Do(req)
	// if err != nil {
	//     return err
	// }
	// defer resp.Body.Close()
	// if resp.StatusCode != http.StatusOK {
	//     return fmt.Errorf("Error sending price to main service")
	// }

	return nil
}

// BuyerRequest represents the structure of a buyer's request.
type BuyerRequest struct {
	BuyerID     string `json:"buyer_id"`
	ItemDetails string `json:"item_details"`
	// Add other fields as necessary
}

// PriceSubmission represents the structure of the price submission from the seller app.
type PriceSubmission struct {
	SellerID string  `json:"seller_id"`
	BuyerID  string  `json:"buyer_id"`
	Price    float64 `json:"price"`
	// Add other fields as necessary
}
