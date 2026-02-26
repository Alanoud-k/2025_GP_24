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
    if (!childId) return res.status(400).json({ message: "Invalid childId" });

    const accountIds = await getChildAccountIds(childId);

    if (accountIds.length === 0) {
      return res.status(200).json({ status: "success", data: [] });
    }

    const rows = await sql`
      SELECT
        "transactionid",
        "transactiontype",
        "amount",
        "transactiondate",
        "transactionstatus",
        "merchantname",
        "sourcetype",
        "transactioncategory",
        "senderAccountId",
        "receiverAccountId",
        "categorysource"
      FROM "Transaction"
      WHERE "senderAccountId" = ANY(${accountIds})
         OR "receiverAccountId" = ANY(${accountIds})
      ORDER BY "transactiondate" DESC
      LIMIT 200
    `;

    return res.status(200).json({ status: "success", data: rows });
  } catch (err) {
    console.error("getChildTransactions error:", err);
    return res.status(500).json({
      message: "Failed to load child transactions",
      error: err.message,
    });
  }
};