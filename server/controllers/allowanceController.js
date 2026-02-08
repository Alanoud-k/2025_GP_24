// server/controllers/allowanceController.js  (ESM)
import { sql } from "../config/db.js";

/**
 * GET /api/allowance/:childId
 */
export const getAllowanceByChild = async (req, res) => {
  try {
    const childId = Number(req.params.childId);
    if (!childId) return res.status(400).json({ error: "Invalid childId" });

    const rows = await sql`
      SELECT "isenabled", "amount", "savepercentage"
      FROM "AllowanceSetting"
      WHERE "childid" = ${childId}
      LIMIT 1
    `;

    if (rows.length === 0) {
      // Default values if not set yet
      return res.json({
        isEnabled: false,
        amount: 0,
        savePercentage: 20,
      });
    }

    const r = rows[0];
    return res.json({
      isEnabled: r.isenabled,
      amount: Number(r.amount ?? 0),
      savePercentage: Number(r.savepercentage ?? 20),
    });
  } catch (err) {
    console.error("getAllowanceByChild error:", err);
    return res.status(500).json({ error: "Failed to fetch allowance settings" });
  }
};

/**
 * PUT /api/allowance/:childId
 * body: { isEnabled, amount, savePercentage }
 */
export const upsertAllowanceByChild = async (req, res) => {
  try {
    const childId = Number(req.params.childId);
    if (!childId) return res.status(400).json({ error: "Invalid childId" });

    const { isEnabled, amount, savePercentage } = req.body;

    const enabled = Boolean(isEnabled);
    const amt = Number(amount);
    const sp = Number(savePercentage);

    if (!Number.isFinite(amt) || amt < 0) {
      return res.status(400).json({ error: "amount must be a number >= 0" });
    }
    if (!Number.isFinite(sp) || sp < 0 || sp > 100) {
      return res
        .status(400)
        .json({ error: "savePercentage must be between 0 and 100" });
    }

    const rows = await sql`
      INSERT INTO "AllowanceSetting" ("childid","isenabled","amount","savepercentage","updatedat")
      VALUES (${childId}, ${enabled}, ${amt}, ${sp}, CURRENT_TIMESTAMP)
      ON CONFLICT ("childid") DO UPDATE SET
        "isenabled" = EXCLUDED."isenabled",
        "amount" = EXCLUDED."amount",
        "savepercentage" = EXCLUDED."savepercentage",
        "updatedat" = CURRENT_TIMESTAMP
      RETURNING "childid"
    `;

    return res.json({
      message: "Allowance settings saved",
      childId: rows[0].childid,
    });
  } catch (err) {
    console.error("upsertAllowanceByChild error:", err);
    return res.status(500).json({ error: "Failed to save allowance settings" });
  }
};
