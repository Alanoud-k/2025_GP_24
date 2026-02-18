import { sql } from "../config/db.js";
import { predictWithPython } from "../../ml_service/predictWithPython.js";
import { keywordMap } from "../../ml_service/keywordMap.js";


export async function categorize(req, res) {
  const merchantText = req.body?.merchant_text;

  if (!merchantText) {
    return res.status(400).json({ error: "merchant_text is required" });
  }

  try {
    const rows = await sql`
      SELECT category
      FROM merchant_rules
      WHERE merchant_text = ${merchantText}
      LIMIT 1
    `;

    if (rows.length) {
      return res.json({ category: rows[0].category, source: "lookup" });
    }

    const mapped = keywordMap(merchantText);
    if (mapped) {
      return res.json({ category: mapped, source: "mapping" });
    }

    const predicted = await predictWithPython(merchantText);
    return res.json({ category: predicted, source: "model" });

  } catch (e) {
    return res.status(500).json({ error: "categorization_failed" });
  }
}
