// handlers.go
package main

import (
	"log"
	"net/http"
)

type RequestBody struct {
	Model    string    `json:"model"`
	Messages []Message `json:"messages"`
}

type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type ResponseBody struct {
	Choices []Choice `json:"choices"`
}

type Choice struct {
	Message Message `json:"message"`
}

type GetOpenAIRequest struct {
	Text string `json:"text"`
}

func (app *Config) GetBuyerRequest(w http.ResponseWriter, r *http.Request) {

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		log.Printf("ERROR:Method not allowed %d", http.StatusMethodNotAllowed)
		return
	}

}
