import { sql } from "../config/db.js";

// Fetch all parent wallet transactions
export const getParentTransactions = async (req, res) => {
  try {
    const { parentId } = req.params;

    if (!parentId) {
      return res.status(400).json({
        message: "Missing parentId",
      });
    }

    // Parent Wallet → Accounts → Transactions
    const rows = await sql`
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
        t."receiverAccountId",
        t."gatewayPaymentId",
        t."mcc",
        t."categorysource"
      FROM "Transaction" t
      JOIN "Account" a
        ON a.accountid = t."receiverAccountId"
      JOIN "Wallet" w
        ON w.walletid = a.walletid
      WHERE w.parentid = ${parentId}
      ORDER BY t."transactiondate" DESC;
    `;

    return res.status(200).json({
      status: "success",
      data: rows,
    });

  } catch (err) {
    console.error("getParentTransactions error:", err);
    return res.status(500).json({
      message: "Internal server error",
      error: err.message,
    });
  }
};
