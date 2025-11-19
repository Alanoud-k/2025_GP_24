// server/controllers/moyasarWebhookController.js

import { sql } from "../config/db.js";

export const handleMoyasarWebhook = async (req, res) => {
  try {
    const event = req.body;

    // بعض نسخة ميسّر ترسل: data → داخل data يكون الدفع
    const payment = event.data ?? event;

    if (!payment) {
      console.error("❌ No payment data in webhook");
      return res.sendStatus(400);
    }

    console.log("📩 Incoming webhook:", payment);

    // نستخدم metadata بدل description (أدق وأفضل)
    const parentId = payment.metadata?.parentId;
    if (!parentId) {
      console.error("❌ parentId missing in metadata");
      return res.sendStatus(400);
    }

    const status = payment.status;
    const amountSAR = payment.amount / 100;
    const gatewayId = payment.id;

    if (status !== "paid") {
      console.log(`ℹ️ Payment not completed (status: ${status})`);
      return res.sendStatus(200);
    }

    console.log(`💸 Paid invoice for Parent ${parentId}: +${amountSAR} SAR`);

    // نمنع التكرار
    const exists = await sql`
      SELECT 1 FROM "Transaction" WHERE "gatewaypaymentid" = ${gatewayId}
    `;
    if (exists.length > 0) {
      console.log("⚠️ Payment already processed, skipping...");
      return res.sendStatus(200);
    }

    // حساب الوالد
    const account = await sql`
      SELECT "accountid" FROM "Account" WHERE "parentid" = ${parentId}
    `;
    if (account.length === 0) {
      console.error("❌ Account not found for parent:", parentId);
      return res.sendStatus(404);
    }

    const receiverAccountId = account[0].accountid;

    // نحدث الرصيد ونضيف Transaction
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
          ${gatewayId}
        )
      `;
    });

    console.log(`✅ Wallet updated successfully for Parent ${parentId}`);

    return res.sendStatus(200);

  } catch (err) {
    console.error("❌ Webhook Error:", err.message);
    return res.sendStatus(500);
  }
};
