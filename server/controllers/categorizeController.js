import { sql } from "../config/db.js";
import keywordMap from "../ml_service/keywordMap.js";
import { predictWithPython } from "../ml_service/predictWithPython.js";

/**
 * Service function:
 * Takes merchantText string and returns predicted category (string).
 */
export async function categorizeTransaction(merchantText) {
  if (!merchantText) return null;

  const text = String(merchantText).toLowerCase().trim();

  // 1) DB lookup
  const lookup = await sql`
    SELECT category
    FROM merchant_lookup
    WHERE lower(merchant_text) = ${text}
    LIMIT 1
  `;
  if (lookup.length > 0) return lookup[0].category;

  // 2) Rule-based keywords
  const ruleCat = keywordMap(text);
  if (ruleCat) {
    // store in lookup for faster next time
    await sql`
      INSERT INTO merchant_lookup (merchant_text, category)
      VALUES (${text}, ${ruleCat})
      ON CONFLICT (merchant_text) DO UPDATE SET category = EXCLUDED.category
    `;
    return ruleCat;
  }

  // 3) ML (Python)
  try {
    const mlCat = await predictWithPython(text);
    if (mlCat) {
      await sql`
        INSERT INTO merchant_lookup (merchant_text, category)
        VALUES (${text}, ${mlCat})
        ON CONFLICT (merchant_text) DO UPDATE SET category = EXCLUDED.category
      `;
      return mlCat;
    }
  } catch (e) {
    console.error("ML prediction failed:", e.message);
  }

  return "Other";
}

/**
 * Express controller:
 * POST /api/categorize
 * Body: { merchantText: string }
 */
export const categorize = async (req, res) => {
  try {
    const { merchantText } = req.body;

    if (!merchantText) {
      return res.status(400).json({ error: "Missing merchantText" });
    }

    const category = await categorizeTransaction(merchantText);

    return res.status(200).json({
      status: "success",
      merchantText,
      category: category ?? "Other",
    });
  } catch (err) {
    console.error("categorize error:", err);
    return res.status(500).json({
      status: "error",
      message: "Categorization failed",
      error: err.message,
    });
  }
};