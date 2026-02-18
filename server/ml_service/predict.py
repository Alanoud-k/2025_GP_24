import json
import sys
import joblib
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

vectorizer = joblib.load(os.path.join(BASE_DIR, "vectorizer.pkl"))
model = joblib.load(os.path.join(BASE_DIR, "model.pkl"))


raw = sys.stdin.read()
data = json.loads(raw or "{}")
merchant_text = data.get("merchant_text", "")

vec = vectorizer.transform([merchant_text])
pred = model.predict(vec)[0]

sys.stdout.write(json.dumps({"prediction": pred}))
