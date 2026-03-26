package handlers

import (
	"net/http"

	"github.com/JulioGastonPita/grcSmart/backend/internal/domain"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type SettingsHandler struct {
	db *gorm.DB
}

func NewSettingsHandler(db *gorm.DB) *SettingsHandler {
	return &SettingsHandler{db: db}
}

func (h *SettingsHandler) Get(c *gin.Context) {
	var s domain.Setting
	result := h.db.First(&s)
	if result.Error == gorm.ErrRecordNotFound {
		c.JSON(http.StatusOK, domain.Setting{})
		return
	}
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}
	c.JSON(http.StatusOK, s)
}

func (h *SettingsHandler) Update(c *gin.Context) {
	var input struct {
		GeminiAPIKey      string `json:"gemini_api_key"`
		LLMModel          string `json:"llm_model"`
		EmbeddingProvider string `json:"embedding_provider"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var s domain.Setting
	h.db.First(&s)

	s.GeminiAPIKey = input.GeminiAPIKey
	s.LLMModel = input.LLMModel
	s.EmbeddingProvider = input.EmbeddingProvider

	if s.ID == 0 {
		h.db.Create(&s)
	} else {
		h.db.Save(&s)
	}

	c.JSON(http.StatusOK, s)
}
