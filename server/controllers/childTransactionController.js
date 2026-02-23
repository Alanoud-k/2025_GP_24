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
        "transactionid","transactiontype","amount","transactiondate",
        "transactionstatus","merchantname","sourcetype","transactioncategory",
        "senderAccountId","receiverAccountId"
      FROM "Transaction"
      WHERE "receiverAccountId" = ANY(${accountIds})
      ORDER BY "transactiondate" DESC
      LIMIT 200
    `;

    return res.json(tx);
  } catch (err) {
    console.error("getChildTransactions error:", err);
    return res.status(500).json({ error: "Failed to load child transactions" });
  }
};