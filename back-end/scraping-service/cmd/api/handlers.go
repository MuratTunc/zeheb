package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/PuerkitoBio/goquery"
)

// Config holds configuration values, including database connections.
type Config struct{}

// scrapeGoldPrice fetches and returns the current gold price from the website.
func scrapeGoldPrice() (float64, error) {
	// URL of the website to scrape
	url := "https://canlidoviz.com/altin-fiyatlari/gram-altin" // Replace with your website's actual URL

	// Send a GET request to the website
	res, err := http.Get(url)
	if err != nil {
		return 0, fmt.Errorf("failed to fetch page: %v", err)
	}
	defer res.Body.Close()

	// Check if the request was successful
	if res.StatusCode != 200 {
		return 0, fmt.Errorf("error: status code %d", res.StatusCode)
	}

	// Parse the HTML content with goquery
	doc, err := goquery.NewDocumentFromReader(res.Body)
	if err != nil {
		return 0, fmt.Errorf("failed to parse HTML: %v", err)
	}

	// Look for the gold price in the page content
	// You will need to inspect the page and adjust the selector based on the actual HTML
	priceStr := doc.Find("span[itemprop='price'][cid='32']").Text()
	priceStr = strings.TrimSpace(priceStr)

	// Convert the price string to a float64
	goldPrice, err := strconv.ParseFloat(priceStr, 64)
	if err != nil {
		return 0, fmt.Errorf("failed to parse gold price: %v", err)
	}

	return goldPrice, nil
}

// ScrapeGoldPriceHandler handles the /api/v1/scrape-gold endpoint.
func (app *Config) ScrapeGoldPriceHandler(w http.ResponseWriter, r *http.Request) {
	// Call the scraping function
	price, err := scrapeGoldPrice()
	if err != nil {
		http.Error(w, "Failed to scrape gold price", http.StatusInternalServerError)
		return
	}

	// Respond with the scraped price
	response := map[string]float64{"goldPriceTRY": price}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}
