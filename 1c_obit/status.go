package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"

	"github.com/joho/godotenv"
    	"github.com/rs/zerolog/log"
)

func main() {
	err := godotenv.Load(".env")
	if err != nil {
		log.Fatal().Err(err).Msg("Error loading .env file")
		os.Exit(1)
	}

	serverURL := os.Getenv("SERVER_URL")
	alias := os.Getenv("DB_ALIAS")
	serverPort := os.Getenv("SERVER_PORT")

	if serverURL == "" || alias == "" || serverPort == "" {
		log.Error().Err(err).Msg("SERVER_URL, ALIAS_URL, SERVER_PORT must be set in .env file")
	}

	requestURL := fmt.Sprintf("http://%s:%s/%s", serverURL, serverPort, alias)
	fmt.Println("Server URL:", requestURL)

	responseBody, err := isServerAvailable(requestURL)
	if err != nil {
		log.Error().Err(err).Msg("Error checking server availability")
		os.Exit(1)
	}

	if responseBody {
		log.Info().Msg("Server is available")
	} else {
		log.Error().Err(err).Msg("Server is not available")
		os.Exit(1)
	}
}


func isServerAvailable(url string) (bool, error) {
	response, err := http.Get(url)
	if err != nil {
		log.Logger.Error().Err(err).Msg("Error making request")
		return false, fmt.Errorf("error making request: %v", err)
	}
	defer response.Body.Close()

	body, err := io.ReadAll(response.Body)
	if err != nil {
		log.Logger.Error().Err(err).Msg("Error reading response body")
		return false, fmt.Errorf("error reading response body: %v", err)
	}

	responseBody := string(body)

	switch response.StatusCode {
	case http.StatusOK, http.StatusCreated:
		if strings.Contains(responseBody, "1C:Enterprise") || strings.Contains(responseBody, "1C:Предприятие") {
			return true, nil
		}
		
		return false, nil

	case http.StatusUnauthorized, http.StatusForbidden:
		log.Logger.Info().Int("statusCode", response.StatusCode).Msg("Server requires authentication")
		return true, nil //Вернул true, ибо ситуация ожидаема
	default:
		log.Logger.Info().
		Int("statusCode", response.StatusCode).
		Str("responseBody", responseBody).
		Msg("Received non-success status code")

		return false, fmt.Errorf("received non-success status code: %d", response.StatusCode)

	}
}
