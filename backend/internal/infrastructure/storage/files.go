package storage

import (
	"fmt"
	"os"
	"path/filepath"
	"time"
)

func Save(uploadsDir, originalName string, content []byte) (string, error) {
	if err := os.MkdirAll(uploadsDir, 0755); err != nil {
		return "", fmt.Errorf("creating uploads dir: %w", err)
	}

	filename := fmt.Sprintf("%d_%s", time.Now().UnixNano(), originalName)
	path := filepath.Join(uploadsDir, filename)

	if err := os.WriteFile(path, content, 0644); err != nil {
		return "", fmt.Errorf("writing file: %w", err)
	}

	return path, nil
}

func Delete(path string) error {
	if err := os.Remove(path); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("deleting file %s: %w", path, err)
	}
	return nil
}
