from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import numpy as np

class MerchantInput(BaseModel):
    merchant_name: str

app = FastAPI()

# Load model + label encoder
model = joblib.load("hassalah_ml_model.pkl")
label_encoder = joblib.load("label_encoder.pkl")

@app.get("/")
def home():
    return {"status": "running"}

@app.post("/predict")
def predict_category(data: MerchantInput):
    merchant = data.merchant_name

    # Predict encoded label (number)
    encoded_pred = model.predict([merchant])[0]

    # Convert numpy type to int
    if isinstance(encoded_pred, (np.integer,)):
        encoded_pred = int(encoded_pred)

    # Decode number → original category name
    decoded_category = label_encoder.inverse_transform([encoded_pred])[0]

    return {
        "merchant_name": merchant,
        "predicted_category": decoded_category
    }
