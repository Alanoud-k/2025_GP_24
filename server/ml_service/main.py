from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import joblib

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PIPE_PATH = os.path.join(BASE_DIR, "pipeline.joblib")

app = FastAPI()

pipe = None

class PredictIn(BaseModel):
    merchant_name: str

@app.on_event("startup")
def load_assets():
    global pipe
    if not os.path.exists(PIPE_PATH):
        raise RuntimeError(f"Missing pipeline file: {PIPE_PATH}")
    pipe = joblib.load(PIPE_PATH)

@app.get("/")
def root():
    return {"status": "ok"}

@app.post("/predict")
def predict(payload: PredictIn):
    if pipe is None:
        raise HTTPException(status_code=500, detail="Pipeline not loaded")

    merchant = payload.merchant_name.strip()
    if merchant == "":
        raise HTTPException(status_code=400, detail="merchant_name is required")

    try:
        pred = pipe.predict([merchant])[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    return {"category": str(pred)}