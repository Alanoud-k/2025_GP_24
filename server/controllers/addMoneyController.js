// server/controllers/addMoneyController.js
import axios from "axios";
import { sql } from "../config/db.js";

const MOYASAR_API_URL = "https://api.moyasar.com/v1/payments";
const MOYASAR_SECRET = process.env.MOYASAR_SECRET_KEY;

// POST /api/parent/:parentId/add-money
// Adds money to parent's Account.balance using saved card (Moyasar test card under the hood)
export async function addMoneyToParentWallet(req, res) {
  const parentId = Number(req.params.parentId);
  const amount = Number(req.body.amount);

  if (!parentId || !amount || amount <= 0) {
    return res.status(400).json({ message: "Missing or invalid fields" });
  }

  try {
    // 1) Check parent has a saved card (for UX only)
    const cards = await sql`
      SELECT "brand", "last4"
      FROM "PaymentMethod"
      WHERE "parentid" = ${parentId}
      LIMIT 1
    `;

    if (!cards.length) {
      return res.status(400).json({ message: "No saved card for this parent" });
    }

    const savedCard = cards[0];

    // 2) Call Moyasar sandbox using test card only (not real stored card data)
    const payment = await axios.post(
      MOYASAR_API_URL,
      {
        amount: Math.round(amount * 100), // SAR -> halalas
        currency: "SAR",
        description: `Add money to parent wallet ${parentId}`,
        source: {
          type: "creditcard",
          number: "4111111111111111", // Moyasar test card
          cvc: "123",
          month: "12",
          year: "25",
          name: "Test Card",
        },
      },
      {
        auth: {
          username: MOYASAR_SECRET,
          password: "",
        },
      }
    );

    if (payment.data.status !== "paid") {
      return res.status(400).json({
        message: "Payment failed in sandbox",
        details: payment.data,
      });
    }

    // 3) Update Account.balance for ParentAccount using Wallet + Account tables
    let newBalance;

    await sql.begin(async (tx) => {
      // 3.1) Ensure parent has a wallet row
      let walletId;
      const walletRows = await tx`
        SELECT "walletid"
        FROM "Wallet"
        WHERE "parentid" = ${parentId}
        LIMIT 1
      `;

      if (walletRows.length) {
        walletId = walletRows[0].walletid;
      } else {
        const insertedWallet = await tx`
          INSERT INTO "Wallet" ("parentid", "childid", "walletstatus")
          VALUES (${parentId}, NULL, 'Active')
          RETURNING "walletid"
        `;
        walletId = insertedWallet[0].walletid;
      }

      // 3.2) Get or create ParentAccount for this wallet
      const accountRows = await tx`
        SELECT "accountid", "balance"
        FROM "Account"
        WHERE "walletid" = ${walletId}
          AND "accounttype" = 'ParentAccount'
        LIMIT 1
      `;

      if (accountRows.length) {
        const accountId = accountRows[0].accountid;
        const currentBalance = Number(accountRows[0].balance) || 0;

        const updated = await tx`
          UPDATE "Account"
          SET "balance" = ${currentBalance + amount}
          WHERE "accountid" = ${accountId}
          RETURNING "balance"
        `;
        newBalance = updated[0].balance;
      } else {
        const insertedAccount = await tx`
          INSERT INTO "Account"
            ("walletid", "savingaccountid", "accounttype", "currency", "balance", "limitamount")
          VALUES
            (${walletId}, NULL, 'ParentAccount', 'SAR', ${amount}, 0)
          RETURNING "balance"
        `;
        newBalance = insertedAccount[0].balance;
      }
    });

    return res.status(200).json({
      status: "success",
      message: "Money added to parent account (sandbox)",
      newBalance,
      usedCard: {
        brand: savedCard.brand,
        last4: savedCard.last4,
      },
    });
  } catch (err) {
    console.error("addMoneyToParentWallet error:", err.response?.data || err);
    return res.status(500).json({ message: "Server error" });
  }
}
