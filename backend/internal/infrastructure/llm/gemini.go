package llm

import (
	"context"
	"fmt"

	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/option"
)

// GeminiClient implements both Embedder and LLMClient interfaces
// using github.com/google/generative-ai-go/genai v0.13.0
type GeminiClient struct {
	client     *genai.Client
	llmModel   string
	embedModel string
}

func NewGeminiClient(ctx context.Context, apiKey, llmModel string) (*GeminiClient, error) {
	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		return nil, fmt.Errorf("creating gemini client: %w", err)
	}

	return &GeminiClient{
		client:     client,
		llmModel:   llmModel,
		embedModel: "text-embedding-004",
	}, nil
}

func (g *GeminiClient) Embed(ctx context.Context, text string) ([]float32, error) {
	em := g.client.EmbeddingModel(g.embedModel)
	res, err := em.EmbedContent(ctx, genai.Text(text))
	if err != nil {
		return nil, fmt.Errorf("embedding text: %w", err)
	}
	if res.Embedding == nil {
		return nil, fmt.Errorf("nil embedding returned")
	}
	return res.Embedding.Values, nil
}

func (g *GeminiClient) Complete(ctx context.Context, systemPrompt, userMessage string) (string, error) {
	model := g.client.GenerativeModel(g.llmModel)
	model.SystemInstruction = &genai.Content{
		Parts: []genai.Part{genai.Text(systemPrompt)},
	}

	resp, err := model.GenerateContent(ctx, genai.Text(userMessage))
	if err != nil {
		return "", fmt.Errorf("generating content: %w", err)
	}

	if len(resp.Candidates) == 0 || resp.Candidates[0].Content == nil || len(resp.Candidates[0].Content.Parts) == 0 {
		return "", fmt.Errorf("empty response from gemini")
	}

	part := resp.Candidates[0].Content.Parts[0]
	if text, ok := part.(genai.Text); ok {
		return string(text), nil
	}
	return "", fmt.Errorf("unexpected response part type")
}
