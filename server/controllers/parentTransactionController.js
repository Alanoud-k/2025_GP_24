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
  t."transactioncategory",
  t."senderAccountId",
  t."receiverAccountId"
FROM "Transaction" t
JOIN "Account" a_sender
  ON a_sender.accountid = t."senderAccountId"
JOIN "Wallet" w_sender
  ON w_sender.walletid = a_sender.walletid
    AND w_sender.parentid = ${parentId}

UNION ALL

SELECT
  t."transactionid",
  t."transactiontype",
  t."amount",
  t."transactiondate",
  t."transactionstatus",
  t."merchantname",
  t."transactioncategory",
  t."senderAccountId",
  t."receiverAccountId"
FROM "Transaction" t
JOIN "Account" a_receiver
  ON a_receiver.accountid = t."receiverAccountId"
JOIN "Wallet" w_receiver
  ON w_receiver.walletid = a_receiver.walletid
    AND w_receiver.parentid = ${parentId}

ORDER BY "transactiondate" DESC;

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
