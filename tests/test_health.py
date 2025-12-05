from fastapi.testclient import TestClient
from app.main import app as fastapi_app

client = TestClient(fastapi_app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
