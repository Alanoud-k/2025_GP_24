import axios from "axios";
import { sql } from "../config/db.js";

export const simulateCardPayment = async (req, res) => {
  try {
    const { childId, amount, merchantName, mcc } = req.body;

    if (!childId || !amount || !merchantName || !mcc) {
      return res.status(400).json({ message: "Missing fields" });
    }

    // Call ML service
    const mlRes = await axios.post(
      "https://hassalah-ai.up.railway.app/predict",
      {
        merchant_name: merchantName,
        mcc: mcc
      }
    );

    const category = mlRes.data.data.transactioncategory;

    // Save to DB
    const saved = await sql`
      INSERT INTO Transaction (
        amount,
        merchantname,
        transactioncategory,
        receiverAccountId
      )
      VALUES (${amount}, ${merchantName}, ${category}, ${childId})
      RETURNING *;
    `;

    res.json({
      message: "Transaction simulated",
      data: saved[0]
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};
