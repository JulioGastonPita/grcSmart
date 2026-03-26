package handlers

import (
	"io"
	"net/http"
	"strconv"

	"github.com/JulioGastonPita/grcSmart/backend/internal/service"
	"github.com/gin-gonic/gin"
)

type DocumentsHandler struct {
	svc *service.DocumentService
}

func NewDocumentsHandler(svc *service.DocumentService) *DocumentsHandler {
	return &DocumentsHandler{svc: svc}
}

func (h *DocumentsHandler) List(c *gin.Context) {
	docs, err := h.svc.ListAll()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, docs)
}

func (h *DocumentsHandler) Upload(c *gin.Context) {
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "file field required"})
		return
	}
	defer file.Close()

	content, err := io.ReadAll(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "reading file"})
		return
	}

	doc, err := h.svc.Upload(c.Request.Context(), header.Filename, content)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, doc)
}

func (h *DocumentsHandler) Delete(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	if err := h.svc.Delete(c.Request.Context(), uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "document deleted"})
}
