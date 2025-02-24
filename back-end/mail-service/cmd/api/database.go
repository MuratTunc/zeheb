package main

import (
	"fmt"
	"log"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// User model for GORM
type User struct {
	ID          uint      `gorm:"primaryKey"`
	Username    string    `gorm:"unique;not null"`
	MailAddress string    `gorm:"unique;not null"`
	AuthCode    string    `gorm:"not null"`
	Password    string    `gorm:"not null"` // Added Password field
	CreatedAt   time.Time `gorm:"autoCreateTime"`
	UpdatedAt   time.Time `gorm:"autoUpdateTime"`
}

// Config struct to hold database connection
type Config struct {
	DB *gorm.DB
}

// connectToDB retries connecting to PostgreSQL until it succeeds or fails after retries
func connectToDB() (*gorm.DB, error) {
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		DBHost, DBUser, DBPassword, DBName, DBPort)

	var db *gorm.DB
	var err error

	// Retry logic: Try connecting 10 times with a 5-second delay
	for i := 1; i <= 10; i++ {
		db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
		if err == nil {
			fmt.Println("✅ DATABASE connection success!")
			break
		}
		fmt.Printf("⏳ Attempt %d: Waiting for database to be ready...\n", i)
		time.Sleep(5 * time.Second)
	}

	if err != nil {
		log.Fatalf("❌ Failed to connect to database after retries: %v", err)
	}

	// AutoMigrate to create tables
	err = db.AutoMigrate(&User{})
	if err != nil {
		log.Fatalf("❌ Failed to migrate database : %v", err)
	}

	return db, nil
}
