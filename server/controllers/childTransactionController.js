import { sql } from "../config/db.js";

async function getChildAccountIds(childId) {
  const w = await sql`
    SELECT "walletid"
    FROM "Wallet"
    WHERE "childid" = ${childId}
    LIMIT 1
  `;
  if (!w.length) return [];

  const walletId = w[0].walletid;

  const accounts = await sql`
    SELECT "accountid"
    FROM "Account"
    WHERE "walletid" = ${walletId}
      AND "accounttype" IN ('SavingAccount','SpendingAccount')
  `;

  return accounts.map(a => a.accountid);
}

export const getChildTransactions = async (req, res) => {
  try {
    const childId = Number(req.params.childId);
    if (!childId) return res.status(400).json({ error: "Invalid childId" });

    const accountIds = await getChildAccountIds(childId);
    if (accountIds.length === 0) return res.json([]);

    const tx = await sql`
      SELECT
        t."transactionid",
        t."transactiontype",
        t."amount",
        t."transactiondate",
        t."transactionstatus",
        t."merchantname",
        t."sourcetype",
        t."transactioncategory",
        t."senderAccountId",
        t."receiverAccountId"
      FROM "Transaction" t
      JOIN "Account" a_sender
        ON a_sender."accountid" = t."senderAccountId"
      JOIN "Wallet" w_sender
        ON w_sender."walletid" = a_sender."walletid"
      WHERE t."receiverAccountId" = ANY(${accountIds})
        AND w_sender."parentid" IS NOT NULL
        AND t."transactioncategory" IS NOT NULL
        AND btrim(t."transactioncategory") <> ''
        AND LOWER(btrim(t."transactioncategory")) <> 'uncategorized'
      ORDER BY t."transactiondate" DESC
      LIMIT 200
    `;

    return res.json(tx);
  } catch (err) {
    console.error("getChildTransactions error:", err);
    return res.status(500).json({ error: "Failed to load child transactions" });
  }
};