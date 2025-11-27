import { sql } from "../config/db.js";

// Simulate child card payment using ML service
export const simulateCardPayment = async (req, res) => {
  try {
    const {
      childId,
      amount,
      merchantName,
      mcc,
      receiverAccountId, // <-- important
    } = req.body;

    if (!childId || !amount || !merchantName || !mcc || !receiverAccountId) {
      return res.status(400).json({
        message: "Missing required fields",
        details: { childId, amount, merchantName, mcc, receiverAccountId },
      });
    }

    const mlUrl = process.env.ML_URL || "https://hassalah-ai.up.railway.app";

    const mlRes = await fetch(`${mlUrl}/classify`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        merchant_name: merchantName,
        mcc: mcc,
      }),
    });

    if (!mlRes.ok) {
      const text = await mlRes.text();
      console.error("ML service error:", mlRes.status, mlRes.statusText, text);
      return res.status(502).json({
        message: "ML service failed",
        statusCode: mlRes.status,
        body: text,
      });
    }

    const mlData = await mlRes.json();

    const category =
      mlData?.data?.transactioncategory ??
      mlData?.transactioncategory ??
      mlData?.category ??
      "Uncategorized";

    const rows = await sql`
      INSERT INTO "Transaction" (
        "transactiontype",
        "amount",
        "transactionstatus",
        "merchantname",
        "sourcetype",
        "transactioncategory",
        "receiverAccountId"
      )
      VALUES (
        'Transfer',
        ${amount},
        'Completed',
        ${merchantName},
        'Payment',
        ${category},
        ${receiverAccountId}
      )
      RETURNING *;
    `;

    return res.json({
      status: "success",
      data: rows[0],
      mlCategory: category,
      mlRaw: mlData,
    });
  } catch (err) {
    console.error("simulateCardPayment error:", err);
    return res.status(500).json({
      message: "Internal server error",
      error: err.message,
    });
  }
};
