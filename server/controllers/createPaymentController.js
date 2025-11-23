// server/controllers/createPaymentController.js
import axios from "axios";

const MOYASAR_API_URL = "https://api.moyasar.com/v1/payments";
const MOYASAR_SECRET = process.env.MOYASAR_SECRET_KEY;
const APP_URL = "https://2025gp24-production.up.railway.app";

export async function createPayment(req, res) {
  try {
    const parentId = Number(req.params.parentId);
    const amount = Number(req.body.amount);

    if (!parentId || !amount || amount <= 0) {
      return res.status(400).json({ success: false, message: "Invalid parentId or amount" });
    }

    const paymentBody = {
      amount: Math.round(amount * 100),
      currency: "SAR",
      description: "Wallet Top-Up",
      callback_url: `${APP_URL}/payment-success`,
      metadata: { parentId },
      source: {
        type: "creditcard",
        name: "Test User",
        number: "4111111111111111",
        cvc: "123",
        month: "12",
        year: "2028",
        "3ds": true
      }
    };

    const response = await axios.post(MOYASAR_API_URL, paymentBody, {
      auth: { username: MOYASAR_SECRET, password: "" },
      headers: { "Content-Type": "application/json" }
    });

    const redirectUrl = response.data?.source?.transaction_url;

    return res.status(200).json({
      success: true,
      paymentId: response.data.id,
      redirectUrl
    });
  } catch (err) {
    console.error("createPayment error:", err.response?.data || err.message);
    return res.status(500).json({
      success: false,
      message: "Failed to create payment",
      error: err.response?.data || err.message
    });
  }
}
