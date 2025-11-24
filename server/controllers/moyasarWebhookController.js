// server/controllers/moyasarWebhookController.js
import crypto from "crypto";
import { sql } from "../config/db.js";

export const handleMoyasarWebhook = async (req, res) => {
  try {
    const signature = req.headers["x-moyasar-signature"];

    // Step 0 — Handle dashboard validation pings
    if (!signature) {
      console.log("Moyasar validation ping received");
      return res.sendStatus(200);
    }

    const secret = process.env.MOYASAR_WEBHOOK_SECRET;
    if (!secret) {
      console.error("Webhook secret missing");
      return res.sendStatus(500);
    }

    // Step 1 — Validate signature
    const rawBody = req.rawBody;
    if (!rawBody) {
      console.error("Missing raw body");
      return res.sendStatus(400);
    }

    const computed = crypto
      .createHmac("sha256", secret)
      .update(rawBody)
      .digest("hex");

    if (computed !== signature) {
      console.error("Invalid signature");
      return res.sendStatus(401);
    }

    console.log("Webhook signature verified");

    // Step 2 — Parse event
    const event = req.body;
    const payment = event?.data ?? event;

    const status = payment.status;
    const validStatuses = ["paid", "authorized", "captured", "verified"];

    if (!validStatuses.includes(status)) {
      console.log("Ignoring irrelevant status:", status);
      return res.sendStatus(200);
    }

    const parentId = Number(payment.metadata?.parentId);
    const paymentId = payment.id;
    const amountHalala = Number(payment.amount);

    const amountSAR = amountHalala / 100;

    // Step 3 — Prevent duplicate insert
    const dup = await sql`
      SELECT 1 FROM "Transaction"
      WHERE "gatewayPaymentId" = ${paymentId}
      LIMIT 1
    `;

    if (dup.length > 0) {
      console.log("Duplicate payment ignored");
      return res.sendStatus(200);
    }

    // Step 4 — Update balances & create transaction
    await sql.begin(async (trx) => {
      let wallet = await trx`
        SELECT "walletid"
        FROM "Wallet"
        WHERE "parentid" = ${parentId}
        LIMIT 1
        FOR UPDATE
      `;

      let walletId = wallet.length ? wallet[0].walletid : null;

      if (!walletId) {
        const newWallet = await trx`
          INSERT INTO "Wallet" ("parentid", "childid", "walletstatus")
          VALUES (${parentId}, NULL, 'Active')
          RETURNING "walletid"
        `;
        walletId = newWallet[0].walletid;
      }

      let account = await trx`
        SELECT "accountid"
        FROM "Account"
        WHERE "walletid" = ${walletId}
          AND "accounttype" = 'ParentAccount'
        LIMIT 1
        FOR UPDATE
      `;

      let accountId = account.length ? account[0].accountid : null;

      if (!accountId) {
        const newAcc = await trx`
          INSERT INTO "Account"
            ("walletid","accounttype","currency","balance","limitamount")
          VALUES (${walletId}, 'ParentAccount','SAR',0,0)
          RETURNING "accountid"
        `;
        accountId = newAcc[0].accountid;
      }

      await trx`
        UPDATE "Account"
        SET "balance" = "balance" + ${amountSAR}
        WHERE "accountid" = ${accountId}
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
