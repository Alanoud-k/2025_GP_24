from fastapi import FastAPI
import joblib
import numpy as np
import pandas as pd

app = FastAPI()

# Load model
model = joblib.load("hassalah_ml_model.joblib")

@app.post("/predict")
def predict(data: dict):
    merchant = data["merchant_name"]
    mcc = data["mcc"]

    df = pd.DataFrame([{
        "merchant_name": merchant,
        "mcc": mcc
    }])

    prediction = model.predict(df)[0]

    return {"category": prediction}
