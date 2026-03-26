package service

import (
	"context"
	"fmt"

	"github.com/JulioGastonPita/grcSmart/backend/internal/domain"
	"github.com/JulioGastonPita/grcSmart/backend/internal/infrastructure/llm"
	"github.com/JulioGastonPita/grcSmart/backend/internal/infrastructure/storage"
	"github.com/JulioGastonPita/grcSmart/backend/internal/infrastructure/vectordb"
	"gorm.io/gorm"
)

const (
	chunkSize    = 1000
	chunkOverlap = 200
)

type DocumentService struct {
	db          *gorm.DB
	vectorStore *vectordb.ChromaStore
	embedder    llm.Embedder
	uploadsDir  string
}

func NewDocumentService(db *gorm.DB, vs *vectordb.ChromaStore, embedder llm.Embedder, uploadsDir string) *DocumentService {
	return &DocumentService{db: db, vectorStore: vs, embedder: embedder, uploadsDir: uploadsDir}
}

func (s *DocumentService) Upload(ctx context.Context, originalName string, fileContent []byte) (*domain.Document, error) {
	path, err := storage.Save(s.uploadsDir, originalName, fileContent)
	if err != nil {
		return nil, fmt.Errorf("saving file: %w", err)
	}

	doc := &domain.Document{OriginalName: originalName, StoragePath: path}
	if err := s.db.Create(doc).Error; err != nil {
		storage.Delete(path)
		return nil, fmt.Errorf("saving document to db: %w", err)
	}

	text, err := ExtractTextFromPDF(fileContent)
	if err != nil {
		return doc, fmt.Errorf("extracting text (document saved but not indexed): %w", err)
	}

	chunks := ChunkText(text, chunkSize, chunkOverlap)

	embeddingVectors := make([][]float32, 0, len(chunks))
	for _, chunk := range chunks {
		emb, err := s.embedder.Embed(ctx, chunk)
		if err != nil {
			return doc, fmt.Errorf("embedding chunk: %w", err)
		}
		embeddingVectors = append(embeddingVectors, emb)
	}

	if err := s.vectorStore.AddDocumentChunks(ctx, doc.ID, originalName, chunks, embeddingVectors); err != nil {
		return doc, fmt.Errorf("storing in vector db: %w", err)
	}

	return doc, nil
}

func (s *DocumentService) Delete(ctx context.Context, id uint) error {
	var doc domain.Document
	if err := s.db.First(&doc, id).Error; err != nil {
		return fmt.Errorf("document %d not found: %w", id, err)
	}

	if err := s.vectorStore.DeleteDocumentChunks(ctx, id); err != nil {
		return fmt.Errorf("deleting from vector db: %w", err)
	}

	if err := storage.Delete(doc.StoragePath); err != nil {
		return fmt.Errorf("deleting file: %w", err)
	}

	if err := s.db.Delete(&doc).Error; err != nil {
		return fmt.Errorf("deleting from db: %w", err)
	}

	return nil
}

func (s *DocumentService) ListAll() ([]domain.Document, error) {
	var docs []domain.Document
	if err := s.db.Find(&docs).Error; err != nil {
		return nil, fmt.Errorf("listing documents: %w", err)
	}
	return docs, nil
}
