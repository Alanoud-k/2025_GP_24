import { sql } from "../config/db.js";

// Fetch child transactions (incoming + outgoing)
export const getChildTransactions = async (req, res) => {
  try {
    const { childId } = req.params;

    if (!childId) {
      return res.status(400).json({ message: "Missing childId" });
    }

    const cid = Number(childId);
    if (!Number.isInteger(cid) || cid <= 0) {
      return res.status(400).json({ message: "Invalid childId" });
    }

    // Optional pagination
    const limit = Math.min(Number(req.query.limit ?? 50), 200);
    const offset = Math.max(Number(req.query.offset ?? 0), 0);

    const rows = await sql`
      WITH child_accounts AS (
        SELECT a."accountid", a."accounttype"
        FROM "Account" a
        JOIN "Wallet" w ON w."walletid" = a."walletid"
        WHERE w."childid" = ${cid}
      )
      SELECT
        t."transactionid",
        t."transactiontype",
        t."amount",
        t."transactiondate",
        t."merchantname",
        t."transactioncategory",
        ca."accounttype" AS "accountType",
        ca."accountid"   AS "childAccountId",
        CASE 
          WHEN t."receiverAccountId" = ca."accountid" THEN 'IN'
          WHEN t."senderAccountId"   = ca."accountid" THEN 'OUT'
          ELSE NULL
        END AS "direction"
      FROM "Transaction" t
      JOIN child_accounts ca
        ON ca."accountid" IN (t."receiverAccountId", t."senderAccountId")
      ORDER BY t."transactiondate" DESC
      LIMIT ${limit} OFFSET ${offset};
    `;

    return res.status(200).json({
      status: "success",
      childId: cid,
      pagination: { limit, offset, returned: rows.length },
      data: rows,
    });
  } catch (err) {
    console.error("getChildTransactions error:", err);
    return res.status(500).json({
      message: "Internal server error",
      error: err.message,
    });
  }
};