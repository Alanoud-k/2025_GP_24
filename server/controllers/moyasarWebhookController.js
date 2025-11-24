// server/controllers/moyasarWebhookController.js

import { sql } from "../config/db.js";

export const handleMoyasarWebhook = async (req, res) => {
  try {
    console.log("Webhook received");

    const signature = req.headers["x-event-secret"];

    // Validation pings (no secret header)
    if (!signature) {
      console.log("Moyasar validation ping received");
      return res.sendStatus(200);
    }

    const secret = process.env.MOYASAR_WEBHOOK_SECRET;
    if (!secret) {
      console.error("Webhook secret missing");
      return res.sendStatus(500);
    }

    // Compare signature directly
    if (signature !== secret) {
      console.error("Invalid webhook signature");
      return res.sendStatus(401);
    }

    console.log("Webhook signature verified");

    // Parse event body
    const event = req.body;
    console.log("Webhook event body:", event);

    const payment = event?.data ?? event;
    if (!payment || typeof payment !== "object") {
      console.error("Invalid webhook payment object");
      return res.sendStatus(400);
    }

    if (payment.status !== "paid") {
      console.log("Ignoring non-paid status:", payment.status);
      return res.sendStatus(200);
    }

    const parentId = Number(payment.metadata?.parentId);
    const paymentId = payment.id;
    const amountHalala = Number(payment.amount);

    if (!parentId || !paymentId || isNaN(amountHalala)) {
      console.error("Missing payment info in webhook");
      return res.sendStatus(400);
    }

    const amountSAR = amountHalala / 100;

    // Prevent duplicates
    const exists = await sql`
      SELECT 1 FROM "Transaction"
      WHERE "gatewayPaymentId" = ${paymentId}
      LIMIT 1
    `;

    if (exists.length > 0) {
      console.log("Duplicate payment ignored");
      return res.sendStatus(200);
    }

    //
    // ⭐ BEGIN TRANSACTION (Neon-compatible)
    //
    await sql`BEGIN`;

    try {
      // 🔐 Lock wallet
      let walletRows = await sql`
        SELECT "walletid"
        FROM "Wallet"
        WHERE "parentid" = ${parentId}
        FOR UPDATE
        LIMIT 1
      `;

      let walletId = walletRows.length ? walletRows[0].walletid : null;

      // Create wallet if none exists
      if (!walletId) {
        const newWallet = await sql`
          INSERT INTO "Wallet" ("parentid", "childid", "walletstatus")
          VALUES (${parentId}, NULL, 'Active')
          RETURNING "walletid"
        `;
        walletId = newWallet[0].walletid;
      }

      // 🔐 Lock ParentAccount
      let accountRows = await sql`
        SELECT "accountid"
        FROM "Account"
        WHERE "walletid" = ${walletId}
          AND "accounttype" = 'ParentAccount'
        FOR UPDATE
        LIMIT 1
      `;

      let accountId = accountRows.length ? accountRows[0].accountid : null;

      // Create ParentAccount if missing
      if (!accountId) {
        const newAcc = await sql`
          INSERT INTO "Account"
            ("walletid", "accounttype", "currency", "balance", "limitamount")
          VALUES (${walletId}, 'ParentAccount', 'SAR', 0, 0)
          RETURNING "accountid"
        `;
        accountId = newAcc[0].accountid;
      }

      // Update balance
      await sql`
        UPDATE "Account"
        SET "balance" = "balance" + ${amountSAR}
        WHERE "accountid" = ${accountId}
      `;

      // Insert transaction
      await sql`
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

      await sql`COMMIT`;
      console.log("Wallet updated successfully");

    } catch (innerErr) {

      await sql`ROLLBACK`;
      console.error("Transaction failed:", innerErr);
      return res.sendStatus(500);

    }

    return res.sendStatus(200);

  } catch (err) {
    console.error("Webhook error:", err);
    return res.sendStatus(500);
  }
};
