// server/controllers/transactionController.js
import axios from "axios";
import { sql } from "../config/db.js";

export const simulateCardPayment = async (req, res) => {
  try {
    const { childId, amount, merchantName, mcc } = req.body;

    if (!childId || !amount || !merchantName || !mcc) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    // Call ML service
    const mlRes = await axios.post(
      `${process.env.ML_URL}/classify`,
      {
        merchant_name: merchantName,
        mcc: mcc,
      }
    );

    const category = mlRes.data?.category ?? "Uncategorized";

    // Insert fake transaction into DB
    const rows = await sql`
      INSERT INTO "Transaction"
        (transactiontype, amount, transactionstatus,
         merchantname, sourcetype, transactioncategory,
         senderAccountId, receiverAccountId, mcc)
      VALUES
        ('Debit', ${amount}, 'Completed',
         ${merchantName}, 'Payment', ${category},
         NULL, ${childId}, ${mcc})
      RETURNING *;
    `;

    return res.json({
      status: "success",
      data: rows[0],
    });
  } catch (err) {
    console.error("simulateCardPayment error:", err);
    return res.status(500).json({ message: "Internal server error" });
  }
};
