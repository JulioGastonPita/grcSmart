package storage_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/JulioGastonPita/grcSmart/backend/internal/infrastructure/storage"
)

func TestSave_CreatesFile(t *testing.T) {
	dir := t.TempDir()
	content := []byte("fake pdf content")

	path, err := storage.Save(dir, "test.pdf", content)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if _, err := os.Stat(path); os.IsNotExist(err) {
		t.Errorf("file not found at %s", path)
	}

	got, _ := os.ReadFile(path)
	if string(got) != string(content) {
		t.Errorf("content mismatch: got %q want %q", got, content)
	}
}

func TestDelete_RemovesFile(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "test.pdf")
	os.WriteFile(path, []byte("data"), 0644)

	if err := storage.Delete(path); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Error("file should have been deleted")
	}
}
