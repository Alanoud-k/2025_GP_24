from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import joblib

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "model.pkl")
VECTORIZER_PATH = os.path.join(BASE_DIR, "vectorizer.pkl")

app = FastAPI()

model = None
vectorizer = None

class PredictIn(BaseModel):
    merchant_name: str

@app.on_event("startup")
def load_assets():
    global model, vectorizer
    if not os.path.exists(MODEL_PATH):
        raise RuntimeError(f"Missing model file: {MODEL_PATH}")
    if not os.path.exists(VECTORIZER_PATH):
        raise RuntimeError(f"Missing vectorizer file: {VECTORIZER_PATH}")
    model = joblib.load(MODEL_PATH)
    vectorizer = joblib.load(VECTORIZER_PATH)

@app.get("/")
def root():
    return {"status": "ok"}

@app.post("/predict")
def predict(payload: PredictIn):
    if model is None or vectorizer is None:
        raise HTTPException(status_code=500, detail="Assets not loaded")

    merchant = payload.merchant_name.strip()
    if merchant == "":
        raise HTTPException(status_code=400, detail="merchant_name is required")

    try:
        X = vectorizer.transform([merchant])
        pred = model.predict(X)[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    return {"category": str(pred)}