package service_test

import (
	"strings"
	"testing"

	"github.com/JulioGastonPita/grcSmart/backend/internal/service"
)

func TestChunkText_ReturnsChunksOfCorrectSize(t *testing.T) {
	text := strings.Repeat("a", 3000)
	chunks := service.ChunkText(text, 1000, 200)

	if len(chunks) == 0 {
		t.Fatal("expected at least one chunk")
	}

	for i, c := range chunks {
		if len(c) > 1000 {
			t.Errorf("chunk %d too long: %d chars", i, len(c))
		}
	}
}

func TestChunkText_ShortTextReturnsOneChunk(t *testing.T) {
	text := "Short text under limit."
	chunks := service.ChunkText(text, 1000, 200)

	if len(chunks) != 1 {
		t.Errorf("expected 1 chunk, got %d", len(chunks))
	}
	if chunks[0] != text {
		t.Errorf("chunk content mismatch")
	}
}

func TestChunkText_OverlapIsApplied(t *testing.T) {
	text := strings.Repeat("x", 1200)
	chunks := service.ChunkText(text, 1000, 200)

	if len(chunks) < 2 {
		t.Fatal("expected at least 2 chunks")
	}
	expectedStart := text[800:1000]
	if !strings.HasPrefix(chunks[1], expectedStart) {
		t.Error("overlap not applied correctly between chunk 1 and chunk 2")
	}
}
