from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import pandas as pd

app = FastAPI(
    title="Hassalah AI Service",
    description="Spending categorization model API.",
    version="1.0.0",
)

# Input schema
class TransactionInput(BaseModel):
    merchant_name: str
    mcc: int

# Load model once on startup
model = joblib.load("hassalah_ml_model.joblib")


@app.get("/")
def root():
    # Health check endpoint
    return {
        "service": "Hassalah AI",
        "status": "running",
        "info": "Use POST /classify to classify transactions"
    }


@app.post("/classify")
def classify(data: TransactionInput):
    # Prepare input for model
    df = pd.DataFrame([{
        "merchant_name": data.merchant_name,
        "mcc": data.mcc
    }])

    # Predict category
    prediction = model.predict(df)[0]

    return {"category": str(prediction)}
