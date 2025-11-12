const { sql } = require("../config/db");

const handleMoyasarWebhook = async (req, res) => {
  try {
    const payment = req.body.data; // ⚠️ use data field inside the webhook

    if (payment.status === "paid") {
      const parentId = extractParentId(payment.description);
      const amountSAR = payment.amount / 100;

      // 1️⃣ Find the parent’s account
      const account = await sql`
        SELECT accountid FROM "Account" WHERE parentid = ${parentId}
      `;
      if (account.length === 0) {
        console.error("❌ Parent account not found for ID:", parentId);
        return res.sendStatus(404);
      }

      const receiverAccountId = account[0].accountid;

      // 2️⃣ Update balance
      await sql`
        UPDATE "Account"
        SET balance = balance + ${amountSAR}
        WHERE accountid = ${receiverAccountId}
      `;

      // 3️⃣ Insert transaction
      await sql`
        INSERT INTO "Transaction"
          (transactiontype, amount, transactiondate, transactionstatus, merchantname, sourcetype, transactioncategory, senderAccountId, receiverAccountId)
        VALUES ('Deposit', ${amountSAR}, NOW(), 'Success', 'Moyasar', 'Payment Gateway', 'Wallet Top-Up', 0, ${receiverAccountId})
      `;

      console.log(`✅ Wallet updated successfully for Parent ${parentId}`);
    }

    res.sendStatus(200);
  } catch (err) {
    console.error("❌ Webhook Error:", err.message);
    res.sendStatus(500);
  }
};

function extractParentId(description) {
  const match = description.match(/Parent (\d+)/);
  return match ? match[1] : null;
}

module.exports = { handleMoyasarWebhook };
