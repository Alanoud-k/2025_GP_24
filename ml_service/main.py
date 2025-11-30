from fastapi import FastAPI
from pydantic import BaseModel
import joblib

# ===== Load Model (Pipeline) =====
MODEL_PATH = "hassalah_ml_model.pkl"
model = joblib.load(MODEL_PATH)  # Pipeline: TF-IDF + Classifier

# ===== Request Schema =====
class MerchantInput(BaseModel):
    merchant_name: str

# ===== App ======
app = FastAPI()

@app.get("/")
def home():
    return {
        "status": "running",
        "service": "Hassalah ML Service",
        "model": MODEL_PATH
    }

@app.post("/predict")
def predict_category(data: MerchantInput):
    merchant = data.merchant_name
    prediction = model.predict([merchant])[0]
    return {
        "merchant_name": merchant,
        "predicted_category": prediction
    }
