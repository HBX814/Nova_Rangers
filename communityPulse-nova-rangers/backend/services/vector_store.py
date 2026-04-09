import chromadb
from backend.services.embedding_service import embed_text

# Initialize module-level ChromaDB PersistentClient
chroma_client = chromadb.PersistentClient(path="/tmp/chroma_communityPulse")

# Get or create the community_needs collection
collection = chroma_client.get_or_create_collection(name="community_needs")

def add_need(need_id: str, text: str) -> None:
    """
    Embeds the text and adds it to the ChromaDB collection.
    """
    embedding = embed_text(text)
    collection.add(
        ids=[need_id],
        embeddings=[embedding],
        metadatas=[{"need_id": need_id}],
        documents=[text]
    )

def search_similar(text: str, n_results: int = 5) -> list[dict]:
    """
    Finds the n_results most similar needs to the provided text.
    Filters out results with a distance greater than 0.3.
    """
    embedding = embed_text(text)
    
    results = collection.query(
        query_embeddings=[embedding],
        n_results=n_results
    )
    
    similar_needs = []
    
    if results["ids"] and len(results["ids"]) > 0:
        # Extract the results for the single query
        ids = results["ids"][0]
        distances = results["distances"][0]
        documents = results["documents"][0]
        metadatas = results["metadatas"][0]
        
        for i in range(len(ids)):
            dist = distances[i]
            if dist <= 0.3:
                similar_needs.append({
                    "need_id": metadatas[i]["need_id"],
                    "distance": float(dist),
                    "text": documents[i]
                })
                
    return similar_needs

def remove_need(need_id: str) -> None:
    """
    Removes a need from the collection by its ID.
    """
    collection.delete(ids=[need_id])

def collection_count() -> int:
    """
    Returns the number of documents in the collection.
    """
    return collection.count()
