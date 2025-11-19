// server/controllers/parentCardController.js
import { sql } from "../config/db.js";

// GET /api/parent/:parentId/card
export async function getParentCard(req, res) {
  const parentId = Number(req.params.parentId);
  if (!parentId) {
    return res.status(400).json({ message: "Invalid parentId" });
  }

  try {
    const rows = await sql`
      SELECT "brand", "last4", "exp_month", "exp_year"
      FROM "PaymentMethod"
      WHERE "parentid" = ${parentId}
      LIMIT 1
    `;

    if (!rows.length) {
      return res.status(200).json({ hasCard: false });
    }

    const card = rows[0];

    return res.status(200).json({
      hasCard: true,
      brand: card.brand,
      last4: card.last4,
      expMonth: card.exp_month,
      expYear: card.exp_year,
    });
  } catch (err) {
    console.error("getParentCard error:", err);
    res.status(500).json({ message: "Server error" });
  }
}

// POST /api/parent/:parentId/card
export async function saveParentCard(req, res) {
  const parentId = Number(req.params.parentId);
  const { brand, last4, expMonth, expYear } = req.body;

  if (!parentId || !brand || !last4 || !expMonth || !expYear) {
    return res.status(400).json({ message: "Missing fields" });
  }

  try {
    // Delete old card (only one allowed)
    await sql`
      DELETE FROM "PaymentMethod"
      WHERE "parentid" = ${parentId}
    `;

    // Insert new card
    const rows = await sql`
      INSERT INTO "PaymentMethod"
        ("parentid", "brand", "last4", "exp_month", "exp_year")
      VALUES
        (${parentId}, ${brand}, ${last4}, ${expMonth}, ${expYear})
      RETURNING "paymentmethodid"
    `;

    return res.status(201).json({
      message: "Card saved successfully",
      cardId: rows[0].paymentmethodid,
      hasCard: true,
    });
  } catch (err) {
    console.error("saveParentCard error:", err);
    res.status(500).json({ message: "Server error" });
  }
}
