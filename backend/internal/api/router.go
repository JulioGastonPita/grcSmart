package api

import (
	"github.com/JulioGastonPita/grcSmart/backend/internal/api/handlers"
	"github.com/JulioGastonPita/grcSmart/backend/internal/api/middleware"
	"github.com/JulioGastonPita/grcSmart/backend/internal/service"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func NewRouter(db *gorm.DB, docSvc *service.DocumentService, chatSvc *service.ChatService) *gin.Engine {
	r := gin.Default()
	r.Use(middleware.CORS())

	settingsH := handlers.NewSettingsHandler(db)
	documentsH := handlers.NewDocumentsHandler(docSvc)
	chatH := handlers.NewChatHandler(chatSvc)

	api := r.Group("/api")
	{
		api.GET("/health", func(c *gin.Context) { c.JSON(200, gin.H{"status": "ok"}) })
		api.GET("/settings", settingsH.Get)
		api.PUT("/settings", settingsH.Update)
		api.GET("/documents", documentsH.List)
		api.POST("/documents", documentsH.Upload)
		api.DELETE("/documents/:id", documentsH.Delete)
		api.POST("/chat", chatH.Query)
	}

	return r
}
