package llm

import "context"

type Embedder interface {
	Embed(ctx context.Context, text string) ([]float32, error)
}

type LLMClient interface {
	Complete(ctx context.Context, systemPrompt, userMessage string) (string, error)
}
