package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"net/smtp"
	"os"
	"time"
)

// Constants for error and success messages
const (
	ErrInvalidRequestBody = "Invalid request body"
	ErrInsertingUser      = "Error inserting user"
	ErrUserNotFound       = "User not found"
	ErrSendingEmail       = "Failed to send email"
	UserCreatedSuccess    = "User created successfully"
	AuthCodeSuccess       = "Authentication code generated and sent successfully!"
)

// GenerateAuthCode generates a 6-digit random authentication code.
func GenerateAuthCode() string {
	// Create a new random generator using the current Unix timestamp as the seed
	randGen := rand.New(rand.NewSource(time.Now().UnixNano()))
	return fmt.Sprintf("%06d", randGen.Intn(1000000)) // Generates a number between 000000-999999
}

// AuthCodeRequest represents the request payload
type AuthCodeRequest struct {
	Username    string `json:"username"`
	MailAddress string `json:"mailAddress"`
}

// SendMail sends an authentication code to the user's email address
func SendMail(to string, authCode string) error {
	// SMTP server configuration
	smtpHost := "smtp.gmail.com" // Change this for different SMTP providers
	smtpPort := "587"            // TLS port

	// Sender credentials (Use environment variables for security)
	senderEmail := os.Getenv("SMTP_EMAIL")       // Your email address
	senderPassword := os.Getenv("SMTP_PASSWORD") // Your email app password

	// Email message body
	subject := "Subject: Your Authentication Code\n"
	body := fmt.Sprintf("Your authentication code is: %s", authCode)
	message := subject + "\n" + body

	// SMTP authentication
	auth := smtp.PlainAuth("", senderEmail, senderPassword, smtpHost)

	// Send email
	err := smtp.SendMail(smtpHost+":"+smtpPort, auth, senderEmail, []string{to}, []byte(message))
	if err != nil {
		log.Printf("❌ Failed to send email: %v", err)
		return err
	}

	log.Println("✅ Email sent successfully!")
	return nil
}

// GenerateAndSendAuthCode handles the request to generate, store, and send an authentication code.
func (app *Config) GenerateAndSendAuthCode(w http.ResponseWriter, r *http.Request) {
	var req AuthCodeRequest

	// Parse JSON request body
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, ErrInvalidRequestBody, http.StatusBadRequest)
		return
	}

	// Generate a random 6-digit code
	authCode := GenerateAuthCode()

	// Save to database
	user := User{
		Username:    req.Username,
		MailAddress: req.MailAddress,
		AuthCode:    authCode,
	}

	if err := app.DB.Create(&user).Error; err != nil {
		log.Printf("❌ Database error: %v", err)
		http.Error(w, ErrInsertingUser, http.StatusInternalServerError)
		return
	}

	// Send the authentication code via email
	err := SendMail(req.MailAddress, authCode)
	if err != nil {
		http.Error(w, ErrSendingEmail, http.StatusInternalServerError)
		return
	}

	// Respond with success
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": AuthCodeSuccess,
	})
}

// HealthCheckHandler checks if the database is available
func (app *Config) HealthCheckHandler(w http.ResponseWriter, r *http.Request) {
	sqlDB, err := app.DB.DB() // Get *sql.DB from *gorm.DB
	if err != nil {
		http.Error(w, "Failed to get database instance", http.StatusInternalServerError)
		return
	}

	// Check database connectivity
	err = sqlDB.Ping()
	if err != nil {
		http.Error(w, "Database connection failed", http.StatusInternalServerError)
		return
	}

	// If the DB is healthy, return a success response
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}
