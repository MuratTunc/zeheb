package main

// English Error Messages
var errorEng = struct {
	ErrInvalidRequest  string
	ErrUserNotFound    string
	ErrInvalidPassword string
	ErrTokenFailure    string
}{
	ErrInvalidRequest:  "Invalid request body from UI",
	ErrUserNotFound:    "User-mail address not found! Please check your mail address or Signup",
	ErrInvalidPassword: "The password entered is incorrect. Invalid credentials",
	ErrTokenFailure:    "Failed to generate JWT token",
}

// Turkish Error Messages
var errorTr = struct {
	ErrInvalidRequest  string
	ErrUserNotFound    string
	ErrInvalidPassword string
	ErrTokenFailure    string
}{
	ErrInvalidRequest:  "Geçersiz istek gövdesi",
	ErrUserNotFound:    "Kullanıcı e-posta adresi bulunamadı! Lütfen e-posta adresinizi kontrol edin veya Kaydolun",
	ErrInvalidPassword: "Girilen şifre yanlış. Geçersiz kimlik bilgileri",
	ErrTokenFailure:    "JWT belirteci oluşturma başarısız oldu",
}

// Default language (change dynamically in the future)
var currentLang = "eng" // Change to "tr" for Turkish

// Function to return error messages dynamically
func getErrorMessages() struct {
	ErrInvalidRequest  string
	ErrUserNotFound    string
	ErrInvalidPassword string
	ErrTokenFailure    string
} {
	if currentLang == "tr" {
		return errorTr
	}
	return errorEng
}
