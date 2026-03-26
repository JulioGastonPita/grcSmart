package domain

import (
	"time"

	"gorm.io/gorm"
)

type Setting struct {
	gorm.Model
	GeminiAPIKey      string `gorm:"column:gemini_api_key"`
	LLMModel          string `gorm:"column:llm_model;default:'gemini-1.5-flash'"`
	EmbeddingProvider string `gorm:"column:embedding_provider;default:'gemini'"`
}

type Document struct {
	gorm.Model
	OriginalName string    `gorm:"column:original_name;not null"`
	StoragePath  string    `gorm:"column:storage_path;not null"`
	UploadedAt   time.Time `gorm:"column:uploaded_at;autoCreateTime"`
}
