package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"net/smtp"
	"os"
	"time"

	"gorm.io/gorm"
)

// Constants for error and success messages
const (
	ErrInvalidRequestBody = "Invalid request body"
	ErrInsertingUser      = "Error inserting user"
	ErrUserNotFound       = "User not found"
	ErrSendingEmail       = "Failed to send email"
	ErrUpdatingUser       = "Failed to write new generated auth-code to same username and mailaddress"
	UserCreatedSuccess    = "User created successfully"
	ErrDatabase           = "Undifend DTABASE Error"
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

// SendMail sends an authentication code to the user's email address
func SendMail(to string, authCode string) error {
	// SMTP server configuration
	smtpHost := "smtp.gmail.com" // Change this for different SMTP providers
	smtpPort := "587"            // TLS port

	// Sender credentials (Use environment variables for security)
	senderEmail := os.Getenv("MAIL_SERVICE_SMTP_EMAIL")       // Your email address
	senderPassword := os.Getenv("MAIL_SERVICE_SMTP_PASSWORD") // Your email app password

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

	// Check if user already exists
	var existingUser User
	err := app.DB.Where("mail_address = ?", req.MailAddress).First(&existingUser).Error

	if err == nil {
		// User exists -> Update auth_code
		existingUser.AuthCode = authCode
		if err := app.DB.Save(&existingUser).Error; err != nil {
			log.Printf("❌ Database error while updating auth_code: %v", err)
			http.Error(w, ErrUpdatingUser, http.StatusInternalServerError)
			return
		}
	} else if errors.Is(err, gorm.ErrRecordNotFound) {
		// User does not exist -> Create a new record
		newUser := User{
			Username:    req.Username,
			MailAddress: req.MailAddress,
			AuthCode:    authCode,
		}
		if err := app.DB.Create(&newUser).Error; err != nil {
			log.Printf("❌ Database error while inserting new user: %v", err)
			http.Error(w, ErrInsertingUser, http.StatusInternalServerError)
			return
		}
	} else {
		// Other DB error
		log.Printf("❌ Database error: %v", err)
		http.Error(w, ErrDatabase, http.StatusInternalServerError)
		return
	}

	// Send the authentication code via email
	if err := SendMail(req.MailAddress, authCode); err != nil {
		http.Error(w, ErrSendingEmail, http.StatusInternalServerError)
		return
	}

	// Respond with success and return the auth code
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message":  AuthCodeSuccess,
		"authCode": authCode, // Returning auth code in the response
	})
}

// DeleteMailHandler handles the deletion of a user by username and mail address
func (app *Config) DeleteMailHandler(w http.ResponseWriter, r *http.Request) {
	var req AuthCodeRequest // Use the AuthCodeRequest struct

	// Parse the request body
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, ErrInvalidRequestBody, http.StatusBadRequest)
		return
	}

	// Search for the user in the database using the provided username and mail address
	var user User
	if err := app.DB.Where("username = ? AND mail_address = ?", req.Username, req.MailAddress).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			http.Error(w, ErrUserNotFound, http.StatusNotFound)
		} else {
			http.Error(w, "Failed to query the database", http.StatusInternalServerError)
		}
		return
	}

	// Delete the user from the database
	if err := app.DB.Delete(&user).Error; err != nil {
		http.Error(w, "Failed to delete user", http.StatusInternalServerError)
		return
	}

	// Respond with a success message
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("User deleted successfully"))
}
