package config_test

import (
	"os"
	"testing"

	"github.com/JulioGastonPita/grcSmart/backend/internal/config"
)

func TestLoad_UsesEnvVars(t *testing.T) {
	os.Setenv("DB_HOST", "testhost")
	os.Setenv("DB_PORT", "5432")
	os.Setenv("DB_USER", "testuser")
	os.Setenv("DB_PASSWORD", "testpass")
	os.Setenv("DB_NAME", "testdb")
	os.Setenv("CHROMA_URL", "http://localhost:8000")
	os.Setenv("UPLOADS_DIR", "/tmp/uploads")
	defer func() {
		for _, k := range []string{"DB_HOST", "DB_PORT", "DB_USER", "DB_PASSWORD", "DB_NAME", "CHROMA_URL", "UPLOADS_DIR"} {
			os.Unsetenv(k)
		}
	}()

	cfg := config.Load()

	if cfg.DBHost != "testhost" {
		t.Errorf("expected DBHost=testhost, got %s", cfg.DBHost)
	}
	if cfg.ChromaURL != "http://localhost:8000" {
		t.Errorf("expected ChromaURL=http://localhost:8000, got %s", cfg.ChromaURL)
	}
	if cfg.UploadsDir != "/tmp/uploads" {
		t.Errorf("expected UploadsDir=/tmp/uploads, got %s", cfg.UploadsDir)
	}
}

func TestLoad_DefaultPort(t *testing.T) {
	os.Unsetenv("DB_PORT")
	cfg := config.Load()
	if cfg.DBPort != "5432" {
		t.Errorf("expected default DBPort=5432, got %s", cfg.DBPort)
	}
}
