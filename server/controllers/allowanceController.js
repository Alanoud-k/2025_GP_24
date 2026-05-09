// server/controllers/allowanceController.js (ESM)
import { sql } from "../config/db.js";

/**
 * GET /api/allowance/:childId
 */
export const getAllowanceByChild = async (req, res) => {
  try {
    const childId = Number(req.params.childId);
    if (!childId) return res.status(400).json({ error: "Invalid childId" });

    const rows = await sql`
      SELECT "isenabled", "amount", "frequency", "day_of_week", "day_of_month", "time_of_day"
      FROM "AllowanceSetting"
      WHERE "childid" = ${childId}
      LIMIT 1
    `;

    if (rows.length === 0) {
      return res.json({
        isEnabled: false,
        amount: 0,
        frequency: 'Weekly',
        dayOfWeek: 'Sunday',
        dayOfMonth: 1,
        timeOfDay: '08:00'
      });
    }

    const r = rows[0];
    return res.json({
      isEnabled: r.isenabled,
      amount: Number(r.amount ?? 0),
      frequency: r.frequency || 'Weekly',
      dayOfWeek: r.day_of_week || 'Sunday',
      dayOfMonth: r.day_of_month || 1,
      timeOfDay: r.time_of_day || '08:00'
    });
  } catch (err) {
    console.error("getAllowanceByChild error:", err);
    return res.status(500).json({ error: "Failed to fetch allowance settings" });
  }
};

/**
 * PUT /api/allowance/:childId
 */
export const upsertAllowanceByChild = async (req, res) => {
  try {
    const childId = Number(req.params.childId);
    if (!childId) return res.status(400).json({ error: "Invalid childId" });

    const { isEnabled, amount, frequency, dayOfWeek, dayOfMonth, timeOfDay } = req.body;

    const enabled = Boolean(isEnabled);
    const amt = Number(amount);

    // Validation
    if (enabled && (!Number.isFinite(amt) || amt <= 0)) {
        return res.status(400).json({ error: "amount must be > 0 when allowance is enabled" });
    }

    const rows = await sql`
      INSERT INTO "AllowanceSetting" (
        "childid", "isenabled", "amount", "frequency", "day_of_week", "day_of_month", "time_of_day", "updatedat"
      )
      VALUES (
        ${childId}, ${enabled}, ${amt}, ${frequency}, ${dayOfWeek}, ${dayOfMonth}, ${timeOfDay}, CURRENT_TIMESTAMP
      )
      ON CONFLICT ("childid") DO UPDATE SET
        "isenabled" = EXCLUDED."isenabled",
        "amount" = EXCLUDED."amount",
        "frequency" = EXCLUDED."frequency",
        "day_of_week" = EXCLUDED."day_of_week",
        "day_of_month" = EXCLUDED."day_of_month",
        "time_of_day" = EXCLUDED."time_of_day",
        "updatedat" = CURRENT_TIMESTAMP
      RETURNING "childid"
    `;

    return res.json({
      message: "Allowance settings saved successfully",
      childId: rows[0].childid,
    });
  } catch (err) {
    console.error("upsertAllowanceByChild error:", err);
    return res.status(500).json({ error: "Failed to save allowance settings" });
  }
};