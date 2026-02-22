import { sql } from "../config/db.js";
import keywordMap from "../ml_service/keywordMap.js";
import { predictWithPython } from "../ml_service/predictWithPython.js";

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
    // خزنيها في lookup عشان المرة الجاية تكون أسرع
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