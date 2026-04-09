from sentence_transformers import SentenceTransformer

_model = None

def get_model():
    """
    Initializes and returns the sentence-transformer model exactly once.
    """
    global _model
    if _model is None:
        try:
            _model = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')
            print("Embedding model loaded successfully")
        except Exception as e:
            raise RuntimeError(f"Failed to load sentence-transformers model paraphrase-multilingual-MiniLM-L12-v2: {str(e)}")
    return _model

def embed_text(text: str) -> list[float]:
    """
    Generates embedding for the given text using the loaded model.
    """
    model = get_model()
    embedding = model.encode(text)
    return embedding.tolist()
