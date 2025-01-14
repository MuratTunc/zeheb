package main

import (
	"encoding/json"
	"encoding/xml"
	"io"
	"net/http"
	"strconv"
)

// Config holds configuration values, including database connections.
type Config struct{}

// Response structure for USD/TRY exchange rate
type USDTRYResponse struct {
	USDTRY float64 `json:"usdTry"`
}

// Currency struct represents individual currency in TCMB XML data
type Currency struct {
	Code        string `xml:"CurrencyCode,attr"`
	ForexBuying string `xml:"ForexBuying"`
}

// TCMBResponse struct for parsing TCMB XML data
type TCMBResponse struct {
	Currencies []Currency `xml:"Currency"`
}

// Handler function for fetching USD/TRY exchange rate
func (app *Config) GetUSDTRYHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
		return
	}

	// Fetch the USD/TRY rate from TCMB (Central Bank of Turkey)
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

	// Parse the TCMB XML data
	var tcmbData TCMBResponse
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Failed to read TCMB response body", http.StatusInternalServerError)
		return
	}

	if err := xml.Unmarshal(body, &tcmbData); err != nil {
		http.Error(w, "Failed to parse TCMB XML", http.StatusInternalServerError)
		return
	}

	// Find the USD/TRY exchange rate
	var usdForexBuying float64
	for _, currency := range tcmbData.Currencies {
		if currency.Code == "USD" {
			usdForexBuying, err = strconv.ParseFloat(currency.ForexBuying, 64)
			if err != nil {
				http.Error(w, "Invalid USD forex buying rate", http.StatusInternalServerError)
				return
			}
			break
		}
	}

	if usdForexBuying == 0 {
		http.Error(w, "USD forex buying rate not found", http.StatusNotFound)
		return
	}

	// Respond with the USD/TRY exchange rate
	response := USDTRYResponse{
		USDTRY: usdForexBuying,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}
