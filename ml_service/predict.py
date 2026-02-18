import json
import sys
import joblib

vectorizer = joblib.load("vectorizer.pkl")
model = joblib.load("model.pkl")

raw = sys.stdin.read()
data = json.loads(raw or "{}")
merchant_text = data.get("merchant_text", "")

vec = vectorizer.transform([merchant_text])
pred = model.predict(vec)[0]

sys.stdout.write(json.dumps({"prediction": pred}))
