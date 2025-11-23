// server/controllers/moyasarWebhookController.js
import { sql } from "../config/db.js";

export const handleMoyasarWebhook = async (req, res) => {
  try {
    const event = req.body;
    const payment = event?.data ?? event;

    if (!payment || typeof payment !== "object") {
      console.error("Webhook missing payment object");
      return res.sendStatus(400);
    }

    const parentId = payment.metadata?.parentId;
    if (!parentId) {
      console.error("Webhook missing parentId");
      return res.sendStatus(400);
    }

    const status = payment.status;
    const paymentId = payment.id;
    const amount = Number(payment.amount);

    if (!paymentId || Number.isNaN(amount)) {
      console.error("Webhook missing id or amount");
      return res.sendStatus(400);
    }

    const amountSAR = amount / 100;

    if (status !== "paid") {
      console.log(`Payment ignored. Status: ${status}`);
      return res.sendStatus(200);
    }

    // Prevent duplicates
    const exists = await sql`
      SELECT 1
      FROM "Transaction"
      WHERE "gatewayPaymentId" = ${paymentId}
      LIMIT 1
    `;
    if (exists.length > 0) {
      console.log("Payment already processed");
      return res.sendStatus(200);
    }

    // Get parent account
    const account = await sql`
      SELECT "accountid"
      FROM "Account"
      WHERE "parentid" = ${parentId}
      LIMIT 1
    `;
    if (account.length === 0) {
      console.error(`Parent account not found: ${parentId}`);
      return res.sendStatus(404);
    }

    const receiverAccountId = account[0].accountid;

    // Update balance and insert transaction
    await sql.begin(async (trx) => {
      await trx`
        UPDATE "Account"
        SET "balance" = "balance" + ${amountSAR}
        WHERE "accountid" = ${receiverAccountId}
      `;

      await trx`
        INSERT INTO "Transaction"
          ("transactiontype", "amount", "transactiondate", "transactionstatus",
           "merchantname", "sourcetype", "transactioncategory",
           "senderAccountId", "receiverAccountId", "gatewayPaymentId")
        VALUES (
          'Transfer',
          ${amountSAR},
          NOW(),
          'Success',
          'Moyasar',
          'Payment Gateway',
          'Wallet Top-Up',
          ${receiverAccountId},
          ${receiverAccountId},
          ${paymentId}
        )
      `;
    });

    console.log(`Wallet updated for parent ${parentId}`);
    return res.sendStatus(200);
  } catch (err) {
    console.error("Webhook error:", err?.response?.data || err);
    return res.sendStatus(500);
  }
};
