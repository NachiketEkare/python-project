from fastapi import FastAPI
from fastapi.testclient import TestClient
from src.main import app

print("TYPE OF APP:", type(app))
print("APP OBJECT:", app)

assert isinstance(app, FastAPI)

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
