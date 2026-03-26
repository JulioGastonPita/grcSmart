package main

import (
	"context"
	"log"
	"os"

	"github.com/JulioGastonPita/grcSmart/backend/internal/api"
	"github.com/JulioGastonPita/grcSmart/backend/internal/config"
	"github.com/JulioGastonPita/grcSmart/backend/internal/domain"
	"github.com/JulioGastonPita/grcSmart/backend/internal/infrastructure/database"
	"github.com/JulioGastonPita/grcSmart/backend/internal/infrastructure/llm"
	"github.com/JulioGastonPita/grcSmart/backend/internal/infrastructure/vectordb"
	"github.com/JulioGastonPita/grcSmart/backend/internal/service"
	"github.com/gin-gonic/gin"
)

func main() {
	ctx := context.Background()
	cfg := config.Load()

	gin.SetMode(cfg.GinMode)

	db := database.Connect(cfg)

	var settings domain.Setting
	db.First(&settings)

	apiKey := settings.GeminiAPIKey
	if apiKey == "" {
		apiKey = os.Getenv("GEMINI_API_KEY")
	}

	llmModel := settings.LLMModel
	if llmModel == "" {
		llmModel = "gemini-1.5-flash"
	}

	geminiClient, err := llm.NewGeminiClient(ctx, apiKey, llmModel)
	if err != nil {
		log.Fatalf("Failed to create Gemini client: %v", err)
	}

	vectorStore, err := vectordb.NewChromaStore(ctx, cfg.ChromaURL)
	if err != nil {
		log.Fatalf("Failed to connect to ChromaDB: %v", err)
	}

	docSvc := service.NewDocumentService(db, vectorStore, geminiClient, cfg.UploadsDir)
	chatSvc := service.NewChatService(vectorStore, geminiClient, geminiClient)

	r := api.NewRouter(db, docSvc, chatSvc)

	log.Printf("grcSmart backend listening on :8080 (mode: %s)", cfg.GinMode)
	if err := r.Run(":8080"); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}
