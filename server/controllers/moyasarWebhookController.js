// server/controllers/moyasarWebhookController.js

import crypto from "crypto";
import { sql } from "../config/db.js";

export const handleMoyasarWebhook = async (req, res) => {
  try {
    // Allow Moyasar's initial test ping (no signature)
    if (!req.headers["x-moyasar-signature"]) {
      console.log("Moyasar validation ping received");
      return res.sendStatus(200);
    }

    // Step 1: Read signature and secret
    const receivedSignature = req.headers["x-moyasar-signature"];
    const webhookSecret = process.env.MOYASAR_WEBHOOK_SECRET;

    if (!receivedSignature || !webhookSecret) {
      console.log("Missing signature or webhook secret");
      return res.sendStatus(401);
    }

    // Step 2: Validate raw body is available
    const rawBody = req.rawBody;
    if (!rawBody) {
      console.log("Missing rawBody");
      return res.sendStatus(400);
    }

    // Step 3: Compute HMAC signature
    const computedSignature = crypto
      .createHmac("sha256", webhookSecret)
      .update(rawBody)
      .digest("hex");

    if (computedSignature !== receivedSignature) {
      console.log("Invalid webhook signature");
      return res.sendStatus(401);
    }

    console.log("Webhook signature verified");

    // Step 4: Extract payload
    const event = req.body;
    const payment = event?.data ?? event;

    if (!payment || typeof payment !== "object") {
      console.log("Missing payment object");
      return res.sendStatus(400);
    }

    const parentId = Number(payment.metadata?.parentId);
    if (!parentId) {
      console.log("Missing parentId");
      return res.sendStatus(400);
    }

    const paymentId = payment.id;
    const status = payment.status;
    const amountHalala = Number(payment.amount);

    if (!paymentId || Number.isNaN(amountHalala)) {
      console.log("Missing id or amount");
      return res.sendStatus(400);
    }

    // Only process completed payments
    if (status !== "paid") {
      console.log(`Ignoring payment with status: ${status}`);
      return res.sendStatus(200);
    }

    const amountSAR = amountHalala / 100;

    // Step 5: Prevent duplicate transactions
    const exists = await sql`
      SELECT 1 FROM "Transaction"
      WHERE "gatewayPaymentId" = ${paymentId}
      LIMIT 1
    `;
    if (exists.length > 0) {
      console.log("Duplicate payment ignored");
      return res.sendStatus(200);
    }

    // Step 6: Update database in transaction
    await sql.begin(async (trx) => {
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

      let accountRows = await trx`
        SELECT "accountid"
        FROM "Account"
        WHERE "walletid" = ${walletId}
          AND "accounttype" = 'ParentAccount'
        FOR UPDATE
        LIMIT 1
      `;

      let receiverAccountId;
      if (accountRows.length === 0) {
        const newAccount = await trx`
          INSERT INTO "Account"
            ("walletid", "accounttype", "currency", "balance", "limitamount")
          VALUES (${walletId}, 'ParentAccount', 'SAR', 0, 0)
          RETURNING "accountid"
        `;
        receiverAccountId = newAccount[0].accountid;
      } else {
        receiverAccountId = accountRows[0].accountid;
      }

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
          'Deposit',
          ${amountSAR},
          NOW(),
          'Success',
          'Moyasar',
          'Transfer',
          'Wallet Top-Up',
          NULL,
          ${receiverAccountId},
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
