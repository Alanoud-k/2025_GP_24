// server/controllers/addMoneyController.js
import axios from "axios";
import { sql } from "../config/db.js";

const MOYASAR_API_URL = "https://api.moyasar.com/v1/payments";
const MOYASAR_SECRET = process.env.MOYASAR_SECRET_KEY;

export async function addMoneyToParentWallet(req, res) {
  const parentId = Number(req.params.parentId);
  const amount = Number(req.body.amount);

  if (!parentId || !amount || amount <= 0) {
    return res.status(400).json({ message: "Missing or invalid fields" });
  }

  try {
    // 1) Ensure parent has a saved card
    const card = await sql`
      SELECT "brand","last4"
      FROM "PaymentMethod"
      WHERE "parentid" = ${parentId}
      LIMIT 1
    `;

    if (!card.length) {
      return res.status(400).json({
        message: "No saved card found for this parent"
      });
    }

    // 2) Create Moyasar redirect payment (does NOT take stored card!)
    const payment = await axios.post(
      MOYASAR_API_URL,
      {
        amount: Math.round(amount * 100),
        currency: "SAR",
        description: `Add money to parent wallet ${parentId}`,
        callback_url: "https://YOUR-NGROK-URL.ngrok.io/api/moyasar-webhook",
        metadata: { parentId },
        source: {
          type: "creditcard" // triggers redirect UI
        }
      },
      {
        auth: {
          username: MOYASAR_SECRET,
          password: ""
        }
      }
    );

    const redirectUrl = payment.data.source.transaction_url;

    return res.status(200).json({
      success: true,
      transactionUrl: redirectUrl,
      paymentId: payment.data.id
    });

  } catch (err) {
    console.error("addMoneyToParentWallet error:", err.response?.data || err);
    return res.status(500).json({ message: "Server error" });
  }
}
