// server/controllers/createPaymentController.js
import axios from "axios";

const MOYASAR_API_URL = "https://api.moyasar.com/v1/payments";
const MOYASAR_SECRET = process.env.MOYASAR_SECRET_KEY;

export async function createPayment(req, res) {
  try {
    const parentId = Number(req.params.parentId);
    const amount = Number(req.body.amount);

    if (!parentId || !amount || amount <= 0) {
      return res.status(400).json({ message: "Invalid parentId or amount" });
    }

    // ⭐ The EXACT SAME BODY that worked in Postman
    const paymentBody = {
      amount: Math.round(amount * 100),
      currency: "SAR",
      description: "Wallet Top-Up",
      callback_url: "https://2025gp24-production.up.railway.app/payment-success",/////////////////
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

    const response = await axios.post(
      MOYASAR_API_URL,
      paymentBody,
      {
        auth: { username: MOYASAR_SECRET, password: "" }
      }
    );

    const redirectUrl = response.data?.source?.transaction_url;

    return res.status(200).json({
      success: true,
      paymentId: response.data.id,
      redirectUrl: redirectUrl
    });

  } catch (err) {
    console.error("🔥 createPayment error:", err.response?.data || err.message);
    return res.status(500).json({
      success: false,
      message: "Failed to create payment",
      error: err.response?.data || err.message
    });
  }
}
