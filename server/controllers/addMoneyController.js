/*import axios from "axios";
import { sql } from "../config/db.js";

// Add money to parent wallet using Moyasar test card
export const addMoney = async (req, res) => {
  console.log("addMoneyController hit");

  try {
    const { parentId, amount } = req.body;

    if (!parentId || !amount || Number(amount) <= 0) {
      return res
        .status(400)
        .json({ success: false, message: "Invalid amount" });
    }

    const payload = {
      amount: Math.round(Number(amount) * 100),
      currency: "SAR",
      description: `Add money to parent wallet ${parentId}`,
      callback_url:
        "https://2025gp24-production.up.railway.app/api/moyasar-webhook",
      source: {
        type: "creditcard",
        name: "Test Card",
        number: "4242424242424242",
        cvc: "100",
        month: "01",
        year: "25",
      },
    };

    console.log("Moyasar payload:", payload);

    const moyasarRes = await axios.post(
      "https://api.moyasar.com/v1/payments",
      payload,
      {
        auth: {
          username: process.env.MOYASAR_SECRET_KEY,
          password: "",
        },
        headers: { "Content-Type": "application/json" },
      }
    );

    const payment = moyasarRes.data;

    if (payment.status !== "paid") {
      return res.status(402).json({
        success: false,
        message: "Payment not successful",
        status: payment.status,
      });
    }

    const walletRows =
      await sql`SELECT balance FROM parent_wallet WHERE parent_id = ${parentId}`;

    if (walletRows.length === 0) {
      await sql`
        INSERT INTO parent_wallet (parent_id, balance)
        VALUES (${parentId}, ${Number(amount)})
      `;
    } else {
      const oldBalance = Number(walletRows[0].balance);
      const newBalance = oldBalance + Number(amount);

      await sql`
        UPDATE parent_wallet
        SET balance = ${newBalance}
        WHERE parent_id = ${parentId}
      `;
    }

    await sql`
      INSERT INTO transactions (parent_id, amount, type, provider, provider_payment_id, status)
      VALUES (${parentId}, ${Number(amount)}, 'ADD_MONEY', 'MOYASAR', ${payment.id}, 'PAID')
    `;

    const updated =
      await sql`SELECT balance FROM parent_wallet WHERE parent_id = ${parentId}`;

    return res.json({
      success: true,
      message: "Amount added",
      newBalance: Number(updated[0].balance),
      paymentId: payment.id,
    });
  } catch (err) {
    console.error(err.response?.data || err.message);
    return res.status(500).json({
      success: false,
      message: "Server error",
      error: err.response?.data || err.message,
    });
  }
};
*/