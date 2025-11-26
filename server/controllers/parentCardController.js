// server/controllers/parentCardController.js

import { sql } from "../config/db.js";

/* ---------------------------------------------------------
   GET /api/parent/:parentId/card
   Returns saved card for the parent
--------------------------------------------------------- */
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
    return res.status(500).json({ message: "Server error" });
  }
}

/* ---------------------------------------------------------
   POST /api/parent/:parentId/card
   Saves or replaces parent’s saved card
--------------------------------------------------------- */
export async function saveParentCard(req, res) {
  const parentId = Number(req.params.parentId);

  // Flutter sends camelCase fields:
  // brand, last4, expMonth, expYear
  const { brand, last4, expMonth, expYear } = req.body;

  if (!parentId || !brand || !last4 || !expMonth || !expYear) {
    return res.status(400).json({ message: "Missing fields" });
  }

  try {
    // Remove any existing saved card (only one per parent)
    await sql`
      DELETE FROM "PaymentMethod"
      WHERE "parentid" = ${parentId}
    `;

    // Insert new card — map camelCase → snake_case
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
    return res.status(500).json({ message: "Server error" });
  }
}

/* ---------------------------------------------------------
   DELETE /api/parent/:parentId/card
   Removes parent card completely
--------------------------------------------------------- */
export async function deleteParentCard(req, res) {
  const parentId = Number(req.params.parentId);

  if (!parentId) {
    return res.status(400).json({ message: "Invalid parentId" });
  }

  try {
    const result = await sql`
      DELETE FROM "PaymentMethod"
      WHERE "parentid" = ${parentId}
      RETURNING "paymentmethodid"
    `;

    if (!result.length) {
      // no card found, but هذا مو خطأ بالنسبة لنا
      return res.status(404).json({ message: "No card found for this parent" });
    }

    return res.status(200).json({ message: "Card deleted successfully" });
  } catch (err) {
    console.error("deleteParentCard error:", err);
    return res.status(500).json({ message: "Server error" });
  }
}
