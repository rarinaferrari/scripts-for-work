	package main

	import (
		"fmt"
		"io"
		"log"
		"net/http"
		"os"
		"strings"

		"github.com/joho/godotenv"
	)

	func main() {
		err := godotenv.Load(".env")
		if err != nil {
			log.Fatal("Error loading .env file")
			os.Exit(1)
		}

		const serverPort = 8080
		serverURL := os.Getenv("SERVER_URL")
		if serverURL == "" {
			log.Fatal("SERVER_URL must be set in .env file")
		}

		requestURL := fmt.Sprintf("http://%s:%d", serverURL, serverPort)
		fmt.Println("Server URL:", requestURL)
		if isServerAvailable(requestURL) {
			log.Println("Server is available")

		}

		log.Println("Server is not available")
		os.Exit(1)
	}

	func isServerAvailable(url string) bool {
		response, err := http.Get(url)
		if err != nil {
			log.Println("Error making request:", err)
			return false
		}

		defer response.Body.Close()

		if response.StatusCode >= 200 && response.StatusCode < 300 {
			body, err := io.ReadAll(response.Body)
			if err != nil {
				log.Println("Error reading response body:", err)
				return false
			}

			return strings.Contains(string(body), "1С:ПРЕДПРИЯТИЕ") || strings.Contains(string(body), "1С:Предприятие")
		}

		log.Printf("Received non-success status code: %d\n", response.StatusCode)
		return false
	}
