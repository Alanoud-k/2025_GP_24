export const getParentTransactions = async (req, res) => {
  try {
    const { parentId } = req.params;

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
      LEFT JOIN "Account" a1
        ON a1.accountid = t."receiverAccountId"
      LEFT JOIN "Wallet" w1
        ON w1.walletid = a1.walletid
      LEFT JOIN "Account" a2
        ON a2.accountid = t."senderAccountId"
      LEFT JOIN "Wallet" w2
        ON w2.walletid = a2.walletid
      WHERE 
        w1.parentid = ${parentId}
        OR w2.parentid = ${parentId}
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
