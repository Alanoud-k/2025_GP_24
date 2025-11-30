import { sql } from "../config/db.js";

// Simulate child card payment using ML
export const simulateCardPayment = async (req, res) => {
  try {
    const {
      childId,
      amount,
      merchantName,
      receiverAccountId,
    } = req.body;

    if (!childId || !amount || !merchantName || !receiverAccountId) {
      return res.status(400).json({
        message: "Missing required fields",
        details: { childId, amount, merchantName, receiverAccountId },
      });
    }

    const mlUrl = process.env.ML_URL || "https://hassalah-ai.up.railway.app";

    // Call ML service
    const mlRes = await fetch(`${mlUrl}/predict`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        merchant_name: merchantName,
      }),
    });

    if (!mlRes.ok) {
      const text = await mlRes.text();
      return res.status(502).json({
        message: "ML service error",
        statusCode: mlRes.status,
        body: text,
      });
    }

    const mlData = await mlRes.json();

    const category =
      mlData?.predicted_category ||
      mlData?.category ||
      "Uncategorized";

    // Insert transaction 
    const rows = await sql`
      INSERT INTO "Transaction" (
        "transactiontype",
        "amount",
        "transactionstatus",
        "merchantname",
        "sourcetype",
        "transactioncategory",
        "receiverAccountId",
        "categorysource"
      )
      VALUES (
        'Payment',
        ${amount},
        'Success',
        ${merchantName},
        'Payment',
        ${category},
        ${receiverAccountId},
        'ML'
      )
      RETURNING *;
    `;

    return res.status(201).json({
      status: "success",
      data: rows[0],
      mlCategory: category,
    });
  } catch (err) {
    return res.status(500).json({
      message: "Internal server error",
      error: err.message,
    });
  }
};
