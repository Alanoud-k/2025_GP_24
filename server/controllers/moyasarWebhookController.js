// server/controllers/moyasarWebhookController.js

import crypto from "crypto";
import { sql } from "../config/db.js";

export const handleMoyasarWebhook = async (req, res) => {
  try {
    if (!req.headers["x-moyasar-signature"]) {
  console.log("Moyasar validation ping");
  return res.sendStatus(200);
}

    /* ---------------------------------------------------------
       STEP 1 — GET SIGNATURE + SECRET
    --------------------------------------------------------- */
    const receivedSignature = req.headers["x-moyasar-signature"];
    const webhookSecret = process.env.MOYASAR_WEBHOOK_SECRET;

    if (!receivedSignature || !webhookSecret) {
      console.error("Missing signature or secret");
      return res.sendStatus(401);
    }

    /* ---------------------------------------------------------
       STEP 2 — GET RAW BODY TO COMPUTE HMAC
    --------------------------------------------------------- */
    const rawBody = req.rawBody;

    if (!rawBody) {
      console.error("Missing rawBody");
      return res.sendStatus(400);
    }

    const computedSignature = crypto
      .createHmac("sha256", webhookSecret)
      .update(rawBody)
      .digest("hex");

    if (computedSignature !== receivedSignature) {
      console.error("❌ Invalid webhook signature");
      return res.sendStatus(401);
    }

    console.log("✔ Webhook signature verified");

    /* ---------------------------------------------------------
       STEP 3 — PARSE BODY & EXTRACT PAYMENT DATA
    --------------------------------------------------------- */
    const event = req.body;
    const payment = event?.data ?? event;

    if (!payment || typeof payment !== "object") {
      console.error("Webhook missing payment data");
      return res.sendStatus(400);
    }

    const parentId = Number(payment.metadata?.parentId);
    if (!parentId) {
      console.error("Missing parentId in metadata");
      return res.sendStatus(400);
    }

    const paymentId = payment.id;
    const status = payment.status;
    const amountHalala = Number(payment.amount);

    if (!paymentId || Number.isNaN(amountHalala)) {
      console.error("Missing id or amount");
      return res.sendStatus(400);
    }

    // Moyasar sends failed, paid, authorized... we only process "paid"
    if (status !== "paid") {
      console.log(`Ignoring non-paid status: ${status}`);
      return res.sendStatus(200);
    }

    const amountSAR = amountHalala / 100;

    /* ---------------------------------------------------------
       STEP 4 — PREVENT DUPLICATES
    --------------------------------------------------------- */
    const exists = await sql`
      SELECT 1 FROM "Transaction"
      WHERE "gatewayPaymentId" = ${paymentId}
      LIMIT 1
    `;
    if (exists.length > 0) {
      console.log("Duplicate webhook ignored");
      return res.sendStatus(200);
    }

    /* ---------------------------------------------------------
       STEP 5 — PROCESS TOP-UP
    --------------------------------------------------------- */
    await sql.begin(async (trx) => {
      // 1) Ensure wallet exists
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

      // 2) Ensure ParentAccount exists
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

      // 3) Update balance
      await trx`
        UPDATE "Account"
        SET "balance" = "balance" + ${amountSAR}
        WHERE "accountid" = ${receiverAccountId}
      `;

      // 4) Insert transaction
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

    console.log("✔ Wallet updated successfully");

    return res.sendStatus(200);
  } catch (err) {
    console.error("Webhook error:", err);
    return res.sendStatus(500);
  }
  console.log("RAW BODY (hex):", req.rawBody.toString("hex"));
console.log("RECEIVED SIGNATURE:", receivedSignature);
console.log("COMPUTED SIGNATURE:", computedSignature);

};

