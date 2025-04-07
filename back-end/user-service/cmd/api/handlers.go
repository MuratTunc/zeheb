package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/golang-jwt/jwt"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// Constants for error and success messages
const (
	ErrInvalidRequestBody = "Invalid request body"
	ErrHashingPassword    = "Error hashing password"
	ErrInsertingUser      = "Error inserting user"
	ErrUserNotFound       = "User not found"
	ErrInvalidCredentials = "Invalid credentials"
	UserCreatedSuccess    = "User created successfully"
	UserUpdatedSuccess    = "User updated successfully"
	UserDeletedSuccess    = "User deleted successfully"
	LoginSuccess          = "Login successful"
)

// Secret key for JWT signing
var jwtSecret = []byte(JWTSecret)

// HealthCheckHandler checks if the database is available
func (app *Config) HealthCheckHandler(w http.ResponseWriter, r *http.Request) {
	sqlDB, err := app.DB.DB() // Get *sql.DB from *gorm.DB
	if err != nil {
		http.Error(w, "Failed to get database instance", http.StatusInternalServerError)
		return
	}

	// Check database connectivity and return if error occurs
	err = sqlDB.Ping()
	if err != nil {
		http.Error(w, "Database connection failed", http.StatusInternalServerError)
		return
	}

	// If the DB is healthy, return a success response
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

// HashPassword hashes a password using bcrypt
func (app *Config) HashPassword(password string) (string, error) {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(hashedPassword), nil
}

// CheckPassword compares a hashed password with a plain one
func (app *Config) CheckPassword(hashedPassword, password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password))
	return err == nil
}

func (app *Config) CreateUserHandler(w http.ResponseWriter, r *http.Request) {
	var user User
	err := json.NewDecoder(r.Body).Decode(&user)
	if err != nil {
		http.Error(w, ErrInvalidRequestBody, http.StatusBadRequest)
		return
	}

	// Ensure MailAddress is provided
	if user.MailAddress == "" {
		http.Error(w, "Mail address cannot be empty", http.StatusBadRequest)
		return
	}

	// Check if user already exists (by username OR mail address)
	var existingUser User
	if err := app.DB.Where("username = ? OR mail_address = ?", user.Username, user.MailAddress).First(&existingUser).Error; err == nil {
		http.Error(w, "User already exists", http.StatusConflict)
		return
	}

	// Hash the password before saving
	hashedPassword, err := app.HashPassword(user.Password)
	if err != nil {
		http.Error(w, ErrHashingPassword, http.StatusInternalServerError)
		return
	}
	user.Password = hashedPassword

	//  Sets Activated = true for every new user.
	user.Activated = true

	// Insert user into database using GORM
	result := app.DB.Create(&user)
	if result.Error != nil {
		http.Error(w, ErrInsertingUser, http.StatusInternalServerError)
		return
	}

	// Generate JWT token
	token, err := GenerateJWT(user.Username, user.Role)
	if err != nil {
		http.Error(w, "Failed to generate token", http.StatusInternalServerError)
		return
	}

	// Send response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"message":     UserCreatedSuccess,
		"token":       token,
		"mailAddress": user.MailAddress, // Include mail address in the response
	})
}

func (app *Config) LoginUserHandler(w http.ResponseWriter, r *http.Request) {
	var user User
	var storedUser User

	// Parse the incoming request body
	err := json.NewDecoder(r.Body).Decode(&user)
	if err != nil {
		http.Error(w, "Invalid request body from UI", http.StatusBadRequest)
		return
	}

	// Find user in DB by MailAddress
	result := app.DB.Where("mail_address = ?", user.MailAddress).First(&storedUser)
	if result.Error != nil {
		http.Error(w, "User-mail address not found! Please check your mail address ro Signup", http.StatusUnauthorized)
		return
	}

	// Compare passwords (Hash the input password and compare with stored hashed password)
	err = bcrypt.CompareHashAndPassword([]byte(storedUser.Password), []byte(user.Password))
	if err != nil {
		http.Error(w, "The password entered is incorrect. Invalid credentials", http.StatusUnauthorized)
		return
	}

	// Generate JWT token
	token, err := GenerateJWT(storedUser.MailAddress, storedUser.Role)
	if err != nil {
		http.Error(w, "Failed to generate JWT token", http.StatusInternalServerError)
		return
	}

	// Update login_status to true
	storedUser.LoginStatus = true
	app.DB.Save(&storedUser)

	// Send response with token, message, login status, and username
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"token":       token,
		"message":     "Login successful",
		"loginStatus": "true",
		"username":    storedUser.Username, // Add username to the response
	})
}

func (app *Config) UpdatePasswordHandler(w http.ResponseWriter, r *http.Request) {
	var requestData struct {
		Username    string `json:"username"`
		NewPassword string `json:"new_password"`
	}

	// Decode request body
	err := json.NewDecoder(r.Body).Decode(&requestData)
	if err != nil {
		http.Error(w, ErrInvalidRequestBody, http.StatusBadRequest)
		return
	}

	// Log the incoming request for debugging
	fmt.Println("Received request to update password for username:", requestData.Username)

	// Find the user by username
	var user User
	result := app.DB.Where("username = ?", requestData.Username).First(&user)

	// Log the result of the query to help debug
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			http.Error(w, ErrUserNotFound, http.StatusNotFound)
			fmt.Println("User not found:", requestData.Username) // Add log for failed query
			return
		}
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	// Log the found user for debugging
	fmt.Println("Found user:", user)

	// Hash new password
	hashedPassword, err := app.HashPassword(requestData.NewPassword)
	if err != nil {
		http.Error(w, ErrHashingPassword, http.StatusInternalServerError)
		return
	}

	// Update the password
	user.Password = hashedPassword
	app.DB.Save(&user)

	// Log successful password update
	fmt.Println("Password updated for user:", requestData.Username)

	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "Password updated successfully")
}

func (app *Config) GetUserHandler(w http.ResponseWriter, r *http.Request) {
	var user User
	id := r.URL.Query().Get("id")

	// Fetch the user by ID from the database
	result := app.DB.First(&user, id)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			http.Error(w, ErrUserNotFound, http.StatusNotFound)
			return
		}
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	// Check if the MailAddress is empty and log a warning or handle appropriately
	if user.MailAddress == "" {
		// You can log this if necessary or handle the empty field case
		fmt.Println("Warning: User has no MailAddress.")
	}

	// Respond with user data in JSON format
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(user)
}

func (app *Config) UpdateUserHandler(w http.ResponseWriter, r *http.Request) {
	// Parse request body to get username and updated fields
	var requestBody struct {
		Username string `json:"username"`
		Password string `json:"password,omitempty"`
		Email    string `json:"email,omitempty"`
		Role     string `json:"role,omitempty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&requestBody); err != nil {
		http.Error(w, ErrInvalidRequestBody, http.StatusBadRequest)
		return
	}

	if requestBody.Username == "" {
		http.Error(w, "Username is required", http.StatusBadRequest)
		return
	}

	// Find user by username
	var user User
	result := app.DB.Where("username = ?", requestBody.Username).First(&user)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			http.Error(w, ErrUserNotFound, http.StatusNotFound)
			return
		}
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	// Update user fields if provided
	if requestBody.Password != "" {
		hashedPassword, err := app.HashPassword(requestBody.Password)
		if err != nil {
			http.Error(w, ErrHashingPassword, http.StatusInternalServerError)
			return
		}
		user.Password = hashedPassword
	}
	if requestBody.Email != "" {
		user.MailAddress = requestBody.Email
	}
	if requestBody.Role != "" {
		user.Role = requestBody.Role
	}

	// Save updated user
	if err := app.DB.Save(&user).Error; err != nil {
		http.Error(w, "Failed to update user", http.StatusInternalServerError)
		return
	}

	// Send success response
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message":  "User updated successfully",
		"username": user.Username,
	})
}

func (app *Config) DeactivateUserHandler(w http.ResponseWriter, r *http.Request) {
	// Parse request body to get username
	var requestBody struct {
		Username string `json:"username"`
	}

	if err := json.NewDecoder(r.Body).Decode(&requestBody); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if requestBody.Username == "" {
		http.Error(w, "Username is required", http.StatusBadRequest)
		return
	}

	// Find user by username
	var user User
	result := app.DB.Where("username = ?", requestBody.Username).First(&user)
	if result.Error != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	// Set Activated to false
	user.Activated = false

	// Update the user in the database
	if err := app.DB.Save(&user).Error; err != nil {
		http.Error(w, "Failed to deactivate user", http.StatusInternalServerError)
		return
	}

	// Send success response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"message":  "User deactivated successfully",
		"username": user.Username,
	})
}

func (app *Config) ActivateUserHandler(w http.ResponseWriter, r *http.Request) {
	// Parse request body to get username
	var requestBody struct {
		Username string `json:"username"`
	}

	if err := json.NewDecoder(r.Body).Decode(&requestBody); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if requestBody.Username == "" {
		http.Error(w, "Username is required", http.StatusBadRequest)
		return
	}

	// Find user by username
	var user User
	result := app.DB.Where("username = ?", requestBody.Username).First(&user)
	if result.Error != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	// Set Activated to true
	user.Activated = true

	// Update the user in the database
	if err := app.DB.Save(&user).Error; err != nil {
		http.Error(w, "Failed to activate user", http.StatusInternalServerError)
		return
	}

	// Send success response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"message":  "User activated successfully",
		"username": user.Username,
	})
}

func (app *Config) UpdateEmailHandler(w http.ResponseWriter, r *http.Request) {
	// Ensure the user is authenticated with JWT
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		http.Error(w, "Missing token", http.StatusUnauthorized)
		return
	}

	// Extract token from "Bearer <token>"
	tokenString := strings.TrimPrefix(authHeader, "Bearer ")
	if tokenString == authHeader {
		http.Error(w, "Invalid token format", http.StatusUnauthorized)
		return
	}

	// Parse and validate JWT
	claims := jwt.MapClaims{}
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		return jwtSecret, nil
	})

	if err != nil || !token.Valid {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	// Parse the request body (expects JSON with username and new email)
	var requestData struct {
		Username string `json:"username"`
		NewEmail string `json:"new_email"`
	}
	if err := json.NewDecoder(r.Body).Decode(&requestData); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Ensure both fields are provided
	if requestData.Username == "" || requestData.NewEmail == "" {
		http.Error(w, "Username and new email are required", http.StatusBadRequest)
		return
	}

	// Validate email format
	if !isValidEmail(requestData.NewEmail) {
		http.Error(w, "Invalid email format", http.StatusBadRequest)
		return
	}

	// Find user by username
	var user User
	result := app.DB.Where("username = ?", requestData.Username).First(&user)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	// Update email
	user.MailAddress = requestData.NewEmail
	if err := app.DB.Save(&user).Error; err != nil {
		http.Error(w, "Failed to update email", http.StatusInternalServerError)
		return
	}

	// Log the email update action (optional)
	fmt.Printf("User %s updated their email to %s\n", user.Username, user.MailAddress)

	// Send success response
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message":   "Email updated successfully",
		"username":  user.Username,
		"new_email": user.MailAddress,
	})
}

func (app *Config) UpdateRoleHandler(w http.ResponseWriter, r *http.Request) {
	// Ensure the user is authenticated with JWT
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		http.Error(w, "Missing token", http.StatusUnauthorized)
		return
	}

	// Extract the token and parse it
	tokenString := strings.TrimPrefix(authHeader, "Bearer ")
	if tokenString == authHeader {
		http.Error(w, "Invalid token format", http.StatusUnauthorized)
		return
	}

	claims := jwt.MapClaims{}
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		return jwtSecret, nil
	})
	if err != nil || !token.Valid {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	// Extract the username and role from the request body
	var requestData struct {
		Username string `json:"username"`
		Role     string `json:"role"`
	}

	// Decode the JSON body into requestData
	decoder := json.NewDecoder(r.Body)
	err = decoder.Decode(&requestData)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Check if username and role are provided
	if requestData.Username == "" {
		http.Error(w, "Username is required", http.StatusBadRequest)
		return
	}
	if requestData.Role == "" {
		http.Error(w, "Role is required", http.StatusBadRequest)
		return
	}

	// Find the user by username
	var user User
	result := app.DB.Where("username = ?", requestData.Username).First(&user)
	if result.RowsAffected == 0 {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	// Update the role
	user.Role = requestData.Role
	result = app.DB.Save(&user)
	if result.Error != nil {
		http.Error(w, "Failed to update role", http.StatusInternalServerError)
		return
	}

	// Respond with the updated user info (or just a success message)
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "User role updated to: %s", user.Role)
}

func (app *Config) DeleteUserHandler(w http.ResponseWriter, r *http.Request) {
	// Parse the username from the request body (assuming JSON format)
	var requestData struct {
		Username string `json:"username"`
	}

	// Decode the JSON body into requestData
	decoder := json.NewDecoder(r.Body)
	err := decoder.Decode(&requestData)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Ensure the username is provided
	if requestData.Username == "" {
		http.Error(w, "Username is required", http.StatusBadRequest)
		return
	}

	// Ensure the user is authenticated with JWT
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		http.Error(w, "Missing token", http.StatusUnauthorized)
		return
	}

	// Extract the token and parse it
	tokenString := strings.TrimPrefix(authHeader, "Bearer ")
	if tokenString == authHeader {
		http.Error(w, "Invalid token format", http.StatusUnauthorized)
		return
	}

	claims := jwt.MapClaims{}
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		return jwtSecret, nil
	})
	if err != nil || !token.Valid {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	// Optional: Add the username from the token to the request context (for logging or further checks)
	authenticatedUsername := claims["username"].(string)

	// Find the user to delete by username
	var user User
	result := app.DB.Where("username = ?", requestData.Username).Delete(&user)

	// If no rows were affected, the user was not found
	if result.RowsAffected == 0 {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	// Log the deletion action (optional)
	fmt.Printf("User %s (Username: %s) deleted by %s\n", user.Username, requestData.Username, authenticatedUsername)

	// Respond with success message
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "User deleted successfully")
}

// Helper function to validate email format (simple validation)
func isValidEmail(email string) bool {
	// You can use a more robust regex or library for email validation
	// Here, a basic validation for a common email format is used
	re := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	return re.MatchString(email)
}

// GenerateJWT creates a JWT token for a user
func GenerateJWT(username, role string) (string, error) {
	claims := jwt.MapClaims{
		"username": username,
		"role":     role,
		"exp":      time.Now().Add(time.Hour * 24).Unix(), // Token expires in 24 hours
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

// AuthMiddleware verifies JWT tokens
func AuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "Missing token", http.StatusUnauthorized)
			return
		}

		// Extract token from "Bearer <token>"
		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader { // No "Bearer " prefix found
			http.Error(w, "Invalid token format", http.StatusUnauthorized)
			return
		}

		// Parse and verify JWT
		claims := jwt.MapClaims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return jwtSecret, nil
		})

		if err != nil || !token.Valid {
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			return
		}

		// Add username and role to request context (optional)
		r.Header.Set("X-Username", claims["username"].(string))
		r.Header.Set("X-Role", claims["role"].(string))

		next.ServeHTTP(w, r) // Call the next handler
	})
}
