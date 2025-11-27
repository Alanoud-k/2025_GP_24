// controllers/transactionsController.js
import axios from "axios";
import { sql } from "../config/db.js";

export const processTransaction = async (req, res) => {
  try {
    const { child_id, amount, merchant_name, mcc } = req.body;

    if (!child_id || !amount || !merchant_name || !mcc) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const mlRes = await axios.post(
      process.env.ML_URL + "/predict",
      {
        merchant_name,
        mcc
      }
    );

    const category = mlRes.data.category ?? "Uncategorized";

    const saved = await sql`
      INSERT INTO transactions (child_id, amount, merchant_name, mcc, category)
      VALUES (${child_id}, ${amount}, ${merchant_name}, ${mcc}, ${category})
      RETURNING *
    `;

    res.json({
      status: "success",
      data: saved[0],
    });
  } catch (err) {
    console.error("Error in processTransaction:", err);
    res.status(500).json({ message: "Error processing transaction" });
  }
};
