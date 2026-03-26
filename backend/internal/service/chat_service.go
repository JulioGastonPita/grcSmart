package service

import (
	"context"
	"fmt"
	"strings"

	"github.com/JulioGastonPita/grcSmart/backend/internal/infrastructure/llm"
	"github.com/JulioGastonPita/grcSmart/backend/internal/infrastructure/vectordb"
)

const systemPromptTemplate = `Eres un asistente experto en políticas y procedimientos corporativos.
Responde SOLO basándote en el siguiente contexto extraído de los documentos oficiales.
Si la información no está en el contexto, responde que no tienes información suficiente.

CONTEXTO:
%s`

type ChatService struct {
	vectorStore *vectordb.ChromaStore
	embedder    llm.Embedder
	llmClient   llm.LLMClient
}

func NewChatService(vs *vectordb.ChromaStore, embedder llm.Embedder, llmClient llm.LLMClient) *ChatService {
	return &ChatService{vectorStore: vs, embedder: embedder, llmClient: llmClient}
}

func (s *ChatService) Query(ctx context.Context, question string) (string, error) {
	queryEmbedding, err := s.embedder.Embed(ctx, question)
	if err != nil {
		return "", fmt.Errorf("embedding question: %w", err)
	}

	contextChunks, err := s.vectorStore.SearchSimilar(ctx, queryEmbedding, topK)
	if err != nil {
		return "", fmt.Errorf("searching similar chunks: %w", err)
	}

	if len(contextChunks) == 0 {
		return "No encontré información relevante en los documentos cargados.", nil
	}

	context := strings.Join(contextChunks, "\n\n---\n\n")
	systemPrompt := fmt.Sprintf(systemPromptTemplate, context)

	answer, err := s.llmClient.Complete(ctx, systemPrompt, question)
	if err != nil {
		return "", fmt.Errorf("generating answer: %w", err)
	}

	return answer, nil
}
