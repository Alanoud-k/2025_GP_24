// server/controllers/moyasarWebhookController.js
import { sql } from "../config/db.js";

export const handleMoyasarWebhook = async (req, res) => {
  // Validate webhook secret
  const receivedSecret =
    req.headers["x-moyasar-signature"] ||
    req.headers["X-Moyasar-Signature"] ||
    req.headers["x-moyasar-signature".toLowerCase()];

  const expectedSecret = process.env.MOYASAR_WEBHOOK_SECRET;

  if (!expectedSecret || receivedSecret !== expectedSecret) {
    console.error("Invalid webhook signature");
    return res.sendStatus(401);
  }

  try {
    const event = req.body;
    const payment = event?.data ?? event;

    if (!payment || typeof payment !== "object") {
      console.error("Webhook missing payment object");
      return res.sendStatus(400);
    }

    const parentId = Number(payment.metadata?.parentId);
    if (!parentId) {
      console.error("Webhook missing parentId");
      return res.sendStatus(400);
    }

    const status = payment.status;
    const paymentId = payment.id;
    const amountHalala = Number(payment.amount);

    if (!paymentId || Number.isNaN(amountHalala)) {
      console.error("Webhook missing id or amount");
      return res.sendStatus(400);
    }

    if (status !== "paid") {
      return res.sendStatus(200);
    }

    const amountSAR = amountHalala / 100;

    // Prevent duplicates by gatewayPaymentId
    const exists = await sql`
      SELECT 1
      FROM "Transaction"
      WHERE "gatewayPaymentId" = ${paymentId}
      LIMIT 1
    `;
    if (exists.length > 0) {
      return res.sendStatus(200);
    }

    await sql.begin(async (trx) => {
      // 1) Get or create wallet for this parent (lock to avoid race)
      let walletRows = await trx`
        SELECT "walletid"
        FROM "Wallet"
        WHERE "parentid" = ${parentId}
        LIMIT 1
        FOR UPDATE
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

      // 2) Get or create ParentAccount linked to wallet
      let accountRows = await trx`
        SELECT "accountid"
        FROM "Account"
        WHERE "walletid" = ${walletId}
          AND "accounttype" = 'ParentAccount'
        LIMIT 1
        FOR UPDATE
      `;

      let receiverAccountId;
      if (accountRows.length === 0) {
        const newAccount = await trx`
          INSERT INTO "Account"
            ("walletid", "accounttype", "currency", "balance", "limitamount")
          VALUES
            (${walletId}, 'ParentAccount', 'SAR', 0, 0)
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

      // 4) Insert transaction (values match your constraints)
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

    return res.sendStatus(200);
  } catch (err) {
    console.error("Webhook error:", err?.response?.data || err);
    return res.sendStatus(500);
  }
};
