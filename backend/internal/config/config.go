package config

import "os"

type Config struct {
	DBHost     string
	DBPort     string
	DBUser     string
	DBPassword string
	DBName     string
	ChromaURL  string
	UploadsDir string
	GinMode    string
}

func Load() Config {
	return Config{
		DBHost:     getEnv("DB_HOST", "localhost"),
		DBPort:     getEnv("DB_PORT", "5432"),
		DBUser:     getEnv("DB_USER", "grcsmart"),
		DBPassword: getEnv("DB_PASSWORD", "grcsmart_pass"),
		DBName:     getEnv("DB_NAME", "grcsmart_db"),
		ChromaURL:  getEnv("CHROMA_URL", "http://localhost:8001"),
		UploadsDir: getEnv("UPLOADS_DIR", "./uploads"),
		GinMode:    getEnv("GIN_MODE", "debug"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
