import { sql } from "../config/db.js";

export const categorize = async (req, res) => {
  try {
    const { transactionId, merchantName, amount } = req.body;

    if (!transactionId) {
      return res.status(400).json({ message: "transactionId is required" });
    }

    const txRows = await sql`
      SELECT "transactionid", "merchantname", "amount"
      FROM "Transaction"
      WHERE "transactionid" = ${transactionId}
      LIMIT 1
    `;

    if (!txRows.length) {
      return res.status(404).json({ message: "Transaction not found" });
    }

    const tx = txRows[0];

    const payload = {
      merchant_name: merchantName ?? tx.merchantname ?? "",
      amount: amount ?? tx.amount ?? null,
    };

    const aiUrl = process.env.AI_BASE_URL;
    if (!aiUrl) {
      return res.status(500).json({ message: "AI_BASE_URL is not set" });
    }

    const aiRes = await fetch(`${aiUrl}/predict`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    if (!aiRes.ok) {
      const text = await aiRes.text();
      return res.status(502).json({ message: "AI service failed", details: text });
    }

    const aiJson = await aiRes.json();
    const category =
      aiJson.category ??
      aiJson.prediction ??
      aiJson.label ??
      aiJson.transactioncategory ??
      null;

    if (!category || String(category).trim() === "") {
      return res.status(422).json({ message: "AI returned empty category" });
    }

    await sql`
      UPDATE "Transaction"
      SET "transactioncategory" = ${String(category).trim()}
      WHERE "transactionid" = ${transactionId}
    `;

    return res.status(200).json({
      status: "success",
      transactionId,
      category: String(category).trim(),
    });
  } catch (err) {
    console.error("categorize error:", err);
    return res.status(500).json({ message: "Internal server error", error: err.message });
  }
};