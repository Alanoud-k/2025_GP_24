import { sql } from "../config/db.js";

// Fetch child transactions
export const getChildTransactions = async (req, res) => {
  try {
    const { childId } = req.params;

    if (!childId) {
      return res.status(400).json({
        message: "Missing childId",
      });
    }

    // Transaction → Account → Wallet → Child
    const rows = await sql`
      SELECT 
        t."transactionid",
        t."transactiontype",
        t."amount",
        t."transactiondate",
        t."merchantname",
        t."transactioncategory"
      FROM "Transaction" t
      JOIN "Account" a 
        ON a.accountid = t."receiverAccountId"
      JOIN "Wallet" w 
        ON w.walletid = a.walletid
      WHERE w.childid = ${childId}
      ORDER BY t."transactiondate" DESC;
    `;

    return res.status(200).json({
      status: "success",
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
