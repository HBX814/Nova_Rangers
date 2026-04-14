from backend.routers import analytics as analytics_router


class _FakeDoc:
    def __init__(self, doc_id: str, data: dict):
        self.id = doc_id
        self._data = data

    def to_dict(self):
        return self._data


class _FakeQuery:
    def __init__(self, docs, filters=None):
        self._docs = docs
        self._filters = filters or []

    def where(self, field: str, op: str, value):
        assert op == "=="
        return _FakeQuery(self._docs, self._filters + [(field, value)])

    def stream(self):
        for doc in self._docs:
            data = doc.to_dict() or {}
            if all(data.get(field) == value for field, value in self._filters):
                yield doc


class _FakeDB:
    def __init__(self, collections):
        self._collections = collections

    def collection(self, name: str):
        return _FakeQuery(self._collections.get(name, []))


def test_summary_computes_dynamic_average_response_time(monkeypatch):
    fake_db = _FakeDB(
        {
            "needs": [
                _FakeDoc(
                    "need-1",
                    {
                        "status": "OPEN",
                        "need_category": "FLOOD",
                        "submitted_at": "2026-04-07T10:00:00+00:00",
                    },
                ),
                _FakeDoc(
                    "need-2",
                    {
                        "status": "OPEN",
                        "need_category": "MEDICAL",
                        "submitted_at": "2026-04-07T11:00:00+00:00",
                    },
                ),
            ],
            "volunteers": [
                _FakeDoc("vol-1", {"availability_status": "AVAILABLE"}),
                _FakeDoc("vol-2", {"availability_status": "BUSY"}),
            ],
            "assignments": [
                _FakeDoc(
                    "assgn-1",
                    {
                        "status": "COMPLETED",
                        "assigned_at": "2026-04-10T09:00:00+00:00",
                        "completed_at": "2026-04-10T11:00:00+00:00",
                    },
                ),
                _FakeDoc(
                    "assgn-2",
                    {
                        "status": "COMPLETED",
                        "assigned_at": "2026-04-11T08:30:00+00:00",
                        "completed_at": "2026-04-11T09:30:00+00:00",
                    },
                ),
            ],
        }
    )

    monkeypatch.setattr(analytics_router, "db", fake_db)
    analytics_router.summary_cache.clear()
    summary = analytics_router.get_summary()

    assert summary["open_needs"] == 2
    assert summary["available_volunteers"] == 1
    assert summary["avg_response_time_hours"] == 1.5
    assert summary["total_needs_open"] == summary["open_needs"]
    assert summary["total_volunteers_available"] == summary["available_volunteers"]


def test_summary_returns_none_average_when_no_completed_with_times(monkeypatch):
    fake_db = _FakeDB(
        {
            "needs": [_FakeDoc("need-1", {"status": "OPEN"})],
            "volunteers": [],
            "assignments": [_FakeDoc("assgn-1", {"status": "PENDING"})],
        }
    )

    monkeypatch.setattr(analytics_router, "db", fake_db)
    analytics_router.summary_cache.clear()
    summary = analytics_router.get_summary()

    assert summary["avg_response_time_hours"] is None
