// server/controllers/moyasarWebhookController.js

import { sql } from "../config/db.js";

export const handleMoyasarWebhook = async (req, res) => {
  try {
const signature =
  req.headers["x-event-secret"] ||
  req.headers["x-moyasar-signature"] ||
  req.headers["x-moyasar-signature-v2"];

if (!signature) {
  console.log("No signature header found");
  return res.sendStatus(400);
}

const secret = process.env.MOYASAR_WEBHOOK_SECRET;
if (!secret) {
  console.error("Webhook secret missing in .env");
  return res.sendStatus(500);
}

if (signature !== secret) {
  console.error("Invalid webhook signature");
  return res.sendStatus(401);
}


    console.log("Webhook signature verified");

    // Payment event payload
    const event = req.body;
    console.log("Webhook event body:", JSON.stringify(event));

    const payment = event?.data ?? event;

    if (!payment || typeof payment !== "object") {
      console.error("Webhook missing payment object");
      return res.sendStatus(400);
    }

    const status = payment.status;
    if (status !== "paid") {
      console.log("Ignoring non-paid status:", status);
      return res.sendStatus(200);
    }

    const parentId = Number(payment.metadata?.parentId);
    const paymentId = payment.id;
    const amountHalala = Number(payment.amount);

    if (!parentId || !paymentId || Number.isNaN(amountHalala)) {
      console.error("Missing parentId, id, or amount in payment");
      return res.sendStatus(400);
    }

    const amountSAR = amountHalala / 100;

    // Prevent duplicate processing
    const exists = await sql`
      SELECT 1
      FROM "Transaction"
      WHERE "gatewayPaymentId" = ${paymentId}
      LIMIT 1
    `;

    if (exists.length > 0) {
      console.log("Duplicate payment ignored");
      return res.sendStatus(200);
    }

    // Update wallet, account, and insert transaction
    await sql.begin(async (trx) => {
      // Ensure wallet exists
      let walletRows = await trx`
        SELECT "walletid"
        FROM "Wallet"
        WHERE "parentid" = ${parentId}
        FOR UPDATE
        LIMIT 1
      `;

      let walletId;
      if (walletRows.length === 0) {
        const newWallet = await trx`
          INSERT INTO "Wallet" ("parentid", "childid", "walletstatus")
          VALUES (${parentId}, NULL, 'Active')
          RETURNING "walletid"
        `;
        walletId = newWallet[0].walletid;
      } else {
        walletId = walletRows[0].walletid;
      }

      // Ensure ParentAccount exists
      let accountRows = await trx`
        SELECT "accountid"
        FROM "Account"
        WHERE "walletid" = ${walletId}
          AND "accounttype" = 'ParentAccount'
        FOR UPDATE
        LIMIT 1
      `;

      let accountId;
      if (accountRows.length === 0) {
        const newAccount = await trx`
          INSERT INTO "Account"
            ("walletid", "accounttype", "currency", "balance", "limitamount")
          VALUES (${walletId}, 'ParentAccount', 'SAR', 0, 0)
          RETURNING "accountid"
        `;
        accountId = newAccount[0].accountid;
      } else {
        accountId = accountRows[0].accountid;
      }

      // Update balance
      await trx`
        UPDATE "Account"
        SET "balance" = "balance" + ${amountSAR}
        WHERE "accountid" = ${accountId}
      `;

      // Insert transaction
      await trx`
        INSERT INTO "Transaction"
          ("transactiontype", "amount", "transactiondate", "transactionstatus",
           "merchantname", "sourcetype", "transactioncategory",
           "senderAccountId", "receiverAccountId", "gatewayPaymentId")
        VALUES (
          'Deposit',
          ${amountSAR},
          NOW(),
          'Success',
          'Moyasar',
          'Transfer',
          'Wallet Top-Up',
          NULL,
          ${accountId},
          ${paymentId}
        )
      `;
    });

    console.log("Wallet updated successfully");
    return res.sendStatus(200);
  } catch (err) {
    console.error("Webhook error:", err);
    return res.sendStatus(500);
  }
};
