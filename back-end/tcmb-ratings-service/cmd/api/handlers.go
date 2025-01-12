package main

import (
	"database/sql"
	"encoding/json"
	"encoding/xml"
	"io"
	"net/http"
)

// Config holds configuration values, including database connections.
type Config struct {
	DB *sql.DB // Database connection
}

// Request payload structure
type GoldPriceRequest struct {
	CurrencyCode string `json:"currencyCode"`
}

// Response structure
type GoldPriceResponse struct {
	ForexBuying     string `json:"forexBuying"`
	ForexSelling    string `json:"forexSelling"`
	BanknoteBuying  string `json:"banknoteBuying"`
	BanknoteSelling string `json:"banknoteSelling"`
}

// Currency XML structure
type Currency struct {
	CrossOrder      string `xml:"CrossOrder,attr"`
	Code            string `xml:"CurrencyCode,attr"`
	Unit            string `xml:"Unit"`
	Name            string `xml:"Isim"`
	ForexBuying     string `xml:"ForexBuying"`
	ForexSelling    string `xml:"ForexSelling"`
	BanknoteBuying  string `xml:"BanknoteBuying"`
	BanknoteSelling string `xml:"BanknoteSelling"`
}

type TCMBResponse struct {
	Currencies []Currency `xml:"Currency"`
}

// Handler function
func (app *Config) GetGoldPricesHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
		return
	}

	// Parse JSON request body
	var req GoldPriceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON input", http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Fetch data from TCMB
	url := "https://www.tcmb.gov.tr/kurlar/today.xml"
	resp, err := http.Get(url)
	if err != nil {
		http.Error(w, "Failed to fetch data from TCMB", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		http.Error(w, "Invalid response from TCMB", http.StatusInternalServerError)
		return
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Failed to read response body", http.StatusInternalServerError)
		return
	}

	// Parse XML data
	var tcmbData TCMBResponse
	if err := xml.Unmarshal(body, &tcmbData); err != nil {
		http.Error(w, "Failed to parse XML", http.StatusInternalServerError)
		return
	}

	// Find the requested currency code
	for _, currency := range tcmbData.Currencies {
		if currency.Code == req.CurrencyCode {
			response := GoldPriceResponse{
				ForexBuying:     currency.ForexBuying,
				ForexSelling:    currency.ForexSelling,
				BanknoteBuying:  currency.BanknoteBuying,
				BanknoteSelling: currency.BanknoteSelling,
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(response)
			return
		}
	}

	// If currency code not found
	http.Error(w, "Currency code not found", http.StatusNotFound)
}
