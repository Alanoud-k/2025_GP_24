# ml_service/main.py
import joblib
import pandas as pd
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

# load model (the pipeline you trained)
model = joblib.load("hassalah_ml_model.joblib")

class TransactionInput(BaseModel):
    merchant_name: str
    mcc: int

@app.get("/")
def root():
    return {"message": "Hassalah ML Service is running"}

@app.post("/predict")
def predict_category(data: TransactionInput):
    df = pd.DataFrame([{
        "merchant_name": data.merchant_name,
        "mcc": data.mcc
    }])
    pred = model.predict(df)[0]
    return {"category": str(pred)}
