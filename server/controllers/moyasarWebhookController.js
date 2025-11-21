// server/controllers/moyasarWebhookController.js
import { sql } from "../config/db.js";

export const handleMoyasarWebhook = async (req, res) => {
  try {
    const event = req.body;

    // Some Moyasar versions wrap data inside `data`
    const payment = event.data ?? event;

    if (!payment) {
      console.error("❌ Webhook missing payment object");
      return res.sendStatus(400);
    }

    console.log("📩 Webhook received:", payment);

    const parentId = payment.metadata?.parentId;

    if (!parentId) {
      console.error("❌ Webhook missing parentId");
      return res.sendStatus(400);
    }

    const status = payment.status;
    const amountSAR = payment.amount / 100;
    const paymentId = payment.id;

    if (status !== "paid") {
      console.log(`ℹ️ Payment not completed. Status: ${status}`);
      return res.sendStatus(200);
    }

    // Prevent double-processing
    const exists = await sql`
      SELECT 1 FROM "Transaction" WHERE "gatewaypaymentid" = ${paymentId}
    `;
    if (exists.length > 0) {
      console.log("⚠️ Payment already processed");
      return res.sendStatus(200);
    }

    // Get parent account
    const account = await sql`
      SELECT "accountid"
      FROM "Account"
      WHERE "parentid" = ${parentId}
    `;

    if (account.length === 0) {
      console.error(`❌ Parent account not found: ${parentId}`);
      return res.sendStatus(404);
    }

    const receiverAccountId = account[0].accountid;

    // Update balance & create transaction
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
           "senderAccountId", "receiverAccountId", "gatewaypaymentid")
        VALUES (
          'Deposit',
          ${amountSAR},
          NOW(),
          'Success',
          'Moyasar',
          'Payment Gateway',
          'Wallet Top-Up',
          0,
          ${receiverAccountId},
          ${paymentId}
        )
      `;
    });

    console.log(`✅ Wallet updated: Parent ${parentId} +${amountSAR} SAR`);
    return res.sendStatus(200);

  } catch (err) {
    console.error("🔥 Webhook Error:", err.response?.data || err);
    return res.sendStatus(500);
  }
};
