import { sql } from "../config/db.js";
import { keywordMap } from "../ml_service/keywordMap.js";
import { predictWithPython } from "../ml_service/predictWithPython.js";

export async function categorizeTransaction(merchantText) {
  if (!merchantText) return null;

  const text = String(merchantText).toLowerCase().trim();

  const lookup = await sql`
    SELECT category
    FROM merchant_lookup
    WHERE LOWER(merchant_name) = ${text}
    LIMIT 1
  `;

  if (lookup.length > 0) {
    return lookup[0].category;
  }

  const keywordCategory = keywordMap(text);
  if (keywordCategory) {
    return keywordCategory;
  }

  const modelCategory = await predictWithPython(text);
  return modelCategory || "Uncategorized";
}
