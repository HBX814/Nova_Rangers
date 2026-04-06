"""
Firestore Client
================
Provides a singleton Firestore client.  When FIREBASE_CREDENTIALS_PATH points
to a valid service-account JSON the real Firestore SDK is used.  Otherwise a
lightweight in-memory mock is returned so the codebase remains runnable without
GCP credentials during local development.

To switch to production Firestore, simply set the FIREBASE_CREDENTIALS_PATH
environment variable — no business-logic changes required.
"""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Any

from backend.config import FIREBASE_CREDENTIALS_PATH, FIRESTORE_DATABASE_ID

logger = logging.getLogger(__name__)

_db_instance = None


# =============================================================================
# In-memory mock Firestore (for local dev without GCP credentials)
# =============================================================================

class _MockDocumentReference:
    """Simulates a Firestore document reference backed by a Python dict."""

    def __init__(self, store: dict, collection: str, doc_id: str):
        self._store = store
        self._collection = collection
        self._id = doc_id

    @property
    def id(self) -> str:
        return self._id

    def set(self, data: dict, merge: bool = False) -> None:
        col = self._store.setdefault(self._collection, {})
        if merge and self._id in col:
            col[self._id].update(data)
        else:
            col[self._id] = dict(data)

    def get(self) -> "_MockDocumentSnapshot":
        col = self._store.get(self._collection, {})
        data = col.get(self._id)
        return _MockDocumentSnapshot(self._id, data)

    def update(self, data: dict) -> None:
        col = self._store.get(self._collection, {})
        if self._id in col:
            col[self._id].update(data)

    def delete(self) -> None:
        col = self._store.get(self._collection, {})
        col.pop(self._id, None)


class _MockDocumentSnapshot:
    def __init__(self, doc_id: str, data: dict | None):
        self.id = doc_id
        self._data = data
        self.exists = data is not None

    def to_dict(self) -> dict | None:
        return dict(self._data) if self._data else None


class _MockQuery:
    """Minimal chainable query supporting where / order_by / limit / stream."""

    def __init__(self, docs: list[tuple[str, dict]]):
        self._docs = list(docs)

    def where(self, field: str, op: str, value: Any) -> "_MockQuery":
        ops = {
            "==": lambda a, b: a == b,
            "!=": lambda a, b: a != b,
            "<": lambda a, b: a < b,
            "<=": lambda a, b: a <= b,
            ">": lambda a, b: a > b,
            ">=": lambda a, b: a >= b,
            "in": lambda a, b: a in b,
            "array_contains": lambda a, b: b in a if isinstance(a, list) else False,
        }
        fn = ops.get(op, lambda a, b: False)
        filtered = [(did, d) for did, d in self._docs if fn(d.get(field), value)]
        return _MockQuery(filtered)

    def order_by(self, field: str, direction: str = "ASCENDING") -> "_MockQuery":
        reverse = direction.upper() == "DESCENDING"
        sorted_docs = sorted(self._docs, key=lambda x: x[1].get(field, ""), reverse=reverse)
        return _MockQuery(sorted_docs)

    def limit(self, count: int) -> "_MockQuery":
        return _MockQuery(self._docs[:count])

    def stream(self):
        for doc_id, data in self._docs:
            yield _MockDocumentSnapshot(doc_id, data)

    def get(self):
        return list(self.stream())


class _MockCollectionReference:
    """Simulates a Firestore collection."""

    def __init__(self, store: dict, name: str):
        self._store = store
        self._name = name

    def document(self, doc_id: str | None = None) -> _MockDocumentReference:
        if doc_id is None:
            import uuid
            doc_id = str(uuid.uuid4())
        return _MockDocumentReference(self._store, self._name, doc_id)

    def add(self, data: dict) -> tuple[Any, _MockDocumentReference]:
        import uuid
        doc_id = str(uuid.uuid4())
        ref = self.document(doc_id)
        ref.set(data)
        return None, ref

    def where(self, field: str, op: str, value: Any) -> _MockQuery:
        col = self._store.get(self._name, {})
        return _MockQuery(list(col.items())).where(field, op, value)

    def order_by(self, field: str, direction: str = "ASCENDING") -> _MockQuery:
        col = self._store.get(self._name, {})
        return _MockQuery(list(col.items())).order_by(field, direction)

    def limit(self, count: int) -> _MockQuery:
        col = self._store.get(self._name, {})
        return _MockQuery(list(col.items())).limit(count)

    def stream(self):
        col = self._store.get(self._name, {})
        for doc_id, data in col.items():
            yield _MockDocumentSnapshot(doc_id, data)

    def get(self):
        return list(self.stream())


class _MockFirestoreClient:
    """Top-level mock that behaves like google.cloud.firestore.Client."""

    def __init__(self):
        self._store: dict[str, dict[str, dict]] = {}
        logger.warning(
            "Using IN-MEMORY mock Firestore client. "
            "Set FIREBASE_CREDENTIALS_PATH to use real Firestore."
        )

    def collection(self, name: str) -> _MockCollectionReference:
        return _MockCollectionReference(self._store, name)


# =============================================================================
# Public API
# =============================================================================

def get_firestore_client():
    """
    Return a Firestore client singleton.
    Uses the real SDK when credentials are available, otherwise falls back
    to the in-memory mock.
    """
    global _db_instance
    if _db_instance is not None:
        return _db_instance

    cred_path = Path(FIREBASE_CREDENTIALS_PATH) if FIREBASE_CREDENTIALS_PATH else None

    if cred_path and cred_path.exists():
        try:
            import firebase_admin
            from firebase_admin import credentials, firestore

            if not firebase_admin._apps:
                cred = credentials.Certificate(str(cred_path))
                firebase_admin.initialize_app(cred)

            _db_instance = firestore.client(database_id=FIRESTORE_DATABASE_ID)
            logger.info("Connected to real Firestore (database=%s)", FIRESTORE_DATABASE_ID)
        except Exception as exc:
            logger.error("Failed to initialise real Firestore: %s — falling back to mock", exc)
            _db_instance = _MockFirestoreClient()
    else:
        _db_instance = _MockFirestoreClient()

    return _db_instance
