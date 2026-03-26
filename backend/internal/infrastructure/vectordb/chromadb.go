package vectordb

import (
	"context"
	"fmt"

	chromago "github.com/amikos-tech/chroma-go/pkg/api/v2"
	"github.com/amikos-tech/chroma-go/pkg/embeddings"
)

const collectionName = "grcsmart_documents"

// ChromaStore wraps a Chroma collection for vector operations.
// Adapted for github.com/amikos-tech/chroma-go v0.4.0 which uses
// pkg/api/v2 instead of the top-level package used in earlier versions.
type ChromaStore struct {
	client     chromago.Client
	collection chromago.Collection
}

func NewChromaStore(ctx context.Context, chromaURL string) (*ChromaStore, error) {
	client, err := chromago.NewHTTPClient(chromago.WithBaseURL(chromaURL))
	if err != nil {
		return nil, fmt.Errorf("creating chroma client: %w", err)
	}

	col, err := client.GetOrCreateCollection(ctx, collectionName)
	if err != nil {
		return nil, fmt.Errorf("getting or creating chroma collection: %w", err)
	}

	return &ChromaStore{client: client, collection: col}, nil
}

func (s *ChromaStore) AddDocumentChunks(ctx context.Context, documentID uint, originalName string, chunks []string, embeddingVectors [][]float32) error {
	ids := make([]chromago.DocumentID, len(chunks))
	metas := make([]chromago.DocumentMetadata, len(chunks))
	embs := make([]embeddings.Embedding, len(chunks))

	for i, chunk := range chunks {
		ids[i] = chromago.DocumentID(fmt.Sprintf("doc_%d_chunk_%d", documentID, i))

		meta, err := chromago.NewDocumentMetadataFromMap(map[string]interface{}{
			"document_id":   int64(documentID),
			"original_name": originalName,
			"chunk_index":   int64(i),
			"text":          chunk,
		})
		if err != nil {
			return fmt.Errorf("creating metadata for chunk %d: %w", i, err)
		}
		metas[i] = meta
		embs[i] = embeddings.NewEmbeddingFromFloat32(embeddingVectors[i])
	}

	err := s.collection.Add(ctx,
		chromago.WithIDs(ids...),
		chromago.WithEmbeddings(embs...),
		chromago.WithMetadatas(metas...),
	)
	if err != nil {
		return fmt.Errorf("adding chunks to chroma: %w", err)
	}

	return nil
}

func (s *ChromaStore) SearchSimilar(ctx context.Context, embedding []float32, k int) ([]string, error) {
	queryEmb := embeddings.NewEmbeddingFromFloat32(embedding)

	results, err := s.collection.Query(ctx,
		chromago.WithQueryEmbeddings(queryEmb),
		chromago.WithNResults(k),
	)
	if err != nil {
		return nil, fmt.Errorf("querying chroma: %w", err)
	}

	var texts []string
	metaGroups := results.GetMetadatasGroups()
	if len(metaGroups) > 0 {
		for _, meta := range metaGroups[0] {
			if text, ok := meta.GetString("text"); ok {
				texts = append(texts, text)
			}
		}
	}

	return texts, nil
}

func (s *ChromaStore) DeleteDocumentChunks(ctx context.Context, documentID uint) error {
	where := chromago.EqInt("document_id", int(documentID))

	err := s.collection.Delete(ctx,
		chromago.WithWhere(where),
	)
	if err != nil {
		return fmt.Errorf("deleting chunks from chroma for document %d: %w", documentID, err)
	}

	return nil
}
