// server/controllers/addMoneyController.js
import axios from "axios";
import { sql } from "../config/db.js";

const MOYASAR_BASE = "https://api.moyasar.com/v1";
const CALLBACK_URL =
  "https://2025gp24-production.up.railway.app/api/moyasar-webhook";

function moyasarAuth() {
  return {
    auth: {
      username: process.env.MOYASAR_SECRET_KEY,
      password: "",
    },
    headers: { "Content-Type": "application/json" },
  };
}

// Create payment and return redirect url
export const addMoney = async (req, res) => {
  try {
    const { parentId, amount } = req.body;

    if (!parentId || !amount || Number(amount) <= 0) {
      return res.status(400).json({
        success: false,
        message: "Invalid parentId or amount",
      });
    }

    const amountHalala = Math.round(Number(amount) * 100);

    const payload = {
      amount: amountHalala,
      currency: "SAR",
      description: `Wallet top-up for parent ${parentId}`,
      callback_url: CALLBACK_URL,
      metadata: {
        parentId: Number(parentId),
      },
      source: {
        type: "creditcard",
        name: "Test Card",
        number: "4242424242424242",
        cvc: "123",
        month: "01",
        year: "26",
      },
    };

    const paymentRes = await axios.post(
      `${MOYASAR_BASE}/payments`,
      payload,
      moyasarAuth()
    );

    const payment = paymentRes.data;
    const redirectUrl =
      payment?.source?.transaction_url ||
      payment?.source?.transactionUrl ||
      payment?.source?.transactionURL;

    return res.json({
      success: true,
      paymentId: payment.id,
      redirectUrl,
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: "Payment creation failed",
      error: err?.response?.data || err?.message || err,
    });
  }
};

// Confirm payment then update wallet/account/transaction
export const confirmPayment = async (req, res) => {
  try {
    const { paymentId } = req.body;

    if (!paymentId) {
      return res.status(400).json({
        success: false,
        message: "Missing paymentId",
      });
    }

    const payRes = await axios.get(
      `${MOYASAR_BASE}/payments/${paymentId}`,
      moyasarAuth()
    );

    const payment = payRes.data;

    if (!payment || typeof payment !== "object") {
      return res.status(400).json({
        success: false,
        message: "Invalid payment object",
      });
    }

    const parentId = payment.metadata?.parentId;
    const status = payment.status;
    const amount = Number(payment.amount);

    if (!parentId || !payment.id || Number.isNaN(amount)) {
      return res.status(400).json({
        success: false,
        message: "Payment missing parentId/id/amount",
      });
    }

    if (status !== "paid") {
      return res.status(409).json({
        success: false,
        message: `Payment not paid yet: ${status}`,
      });
    }

    const amountSAR = amount / 100;

    // Prevent duplicates
    const exists = await sql`
      SELECT 1
      FROM "Transaction"
      WHERE "gatewayPaymentId" = ${payment.id}
      LIMIT 1
    `;
    if (exists.length > 0) {
      return res.json({
        success: true,
        message: "Already processed",
      });
    }

    // Get or create wallet for parent
    let walletRows = await sql`
      SELECT "walletid"
      FROM "Wallet"
      WHERE "parentid" = ${parentId}
      LIMIT 1
    `;

    let walletId;
    if (walletRows.length === 0) {
      const newWallet = await sql`
        INSERT INTO "Wallet" ("parentid", "childid", "walletstatus")
        VALUES (${parentId}, NULL, 'Active')
        RETURNING "walletid"
      `;
      walletId = newWallet[0].walletid;
    } else {
      walletId = walletRows[0].walletid;
    }

    // Get or create parent account linked to wallet
    let accountRows = await sql`
      SELECT "accountid"
      FROM "Account"
      WHERE "walletid" = ${walletId}
        AND "accounttype" = 'ParentAccount'
      LIMIT 1
    `;

    let receiverAccountId;
    if (accountRows.length === 0) {
      const newAccount = await sql`
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

    // Update balance and insert transaction atomically
    const result = await sql.begin(async (trx) => {
      await trx`
        UPDATE "Account"
        SET "balance" = "balance" + ${amountSAR}
        WHERE "accountid" = ${receiverAccountId}
      `;

      const inserted = await trx`
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
          ${payment.id}
        )
        RETURNING "transactionid"
      `;

      const updatedAcc = await trx`
        SELECT "balance" FROM "Account"
        WHERE "accountid" = ${receiverAccountId}
        LIMIT 1
      `;

      return {
        transactionId: inserted[0].transactionid,
        newBalance: updatedAcc[0].balance,
      };
    });

    return res.json({
      success: true,
      message: "Wallet updated",
      parentId,
      amount: amountSAR,
      transactionId: result.transactionId,
      newBalance: result.newBalance,
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: "Confirm payment failed",
      error: err?.response?.data || err?.message || err,
    });
  }
};
