from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import numpy as np

MODEL_PATH = "hassalah_ml_model.pkl"
model = joblib.load(MODEL_PATH)

class MerchantInput(BaseModel):
    merchant_name: str

app = FastAPI()

@app.get("/")
def home():
    return {"status": "running"}

@app.post("/predict")
def predict_category(data: MerchantInput):
    merchant = data.merchant_name

    # Model prediction
    raw_pred = model.predict([merchant])[0]

    # Convert numpy types to pure Python
    if isinstance(raw_pred, (np.int64, np.int32, np.float64, np.float32)):
        raw_pred = raw_pred.item()  # convert to Python int/float
    else:
        raw_pred = str(raw_pred)

    return {
        "merchant_name": merchant,
        "predicted_category": raw_pred
    }
