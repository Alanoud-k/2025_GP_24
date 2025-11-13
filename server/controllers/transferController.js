// server/controllers/transferController.js  (ESM)

import { sql } from "../config/db.js";

/**
 * Ensure parent has a wallet + ParentAccount
 * Returns: { walletId, parentAccountId, parentBalance }
 */
async function ensureParentWalletAndAccount(parentId, s) {
  // Find or create parent wallet
  const w = await s`
    SELECT "walletid" FROM "Wallet"
    WHERE "parentid" = ${parentId}
    LIMIT 1
  `;
  let walletId;
  if (w.length) {
    walletId = w[0].walletid;
  } else {
    const ins = await s`
      INSERT INTO "Wallet"("parentid","childid","walletstatus")
      VALUES (${parentId}, NULL, 'Active')
      RETURNING "walletid"
    `;
    walletId = ins[0].walletid;
  }

  // Ensure ParentAccount exists
  await s`
    INSERT INTO "Account"("walletid","savingaccountid","accounttype","currency","balance","limitamount")
    SELECT ${walletId}, NULL, 'ParentAccount', 'SAR', 0, 0
    WHERE NOT EXISTS (
      SELECT 1 FROM "Account"
      WHERE "walletid" = ${walletId} AND "accounttype" = 'ParentAccount'
    )
  `;

  const pa = await s`
    SELECT "accountid","balance"
    FROM "Account"
    WHERE "walletid" = ${walletId} AND "accounttype" = 'ParentAccount'
    LIMIT 1
  `;
  const parentAccountId = pa[0].accountid;
  const parentBalance = Number(pa[0].balance ?? 0);

  return { walletId, parentAccountId, parentBalance };
}

/**
 * Ensure child has a wallet + SavingAccount + SpendingAccount
 * Returns: { walletId, savingAccountId, spendingAccountId }
 */
async function ensureChildWalletAndCoreAccounts(childId, s) {
  // Find or create child wallet
  const w = await s`
    SELECT "walletid" FROM "Wallet"
    WHERE "childid" = ${childId}
    LIMIT 1
  `;
  let walletId;
  if (w.length) {
    walletId = w[0].walletid;
  } else {
    const ins = await s`
      INSERT INTO "Wallet"("parentid","childid","walletstatus")
      VALUES (NULL, ${childId}, 'Active')
      RETURNING "walletid"
    `;
    walletId = ins[0].walletid;
  }

  // Ensure SavingAccount
  await s`
    INSERT INTO "Account"("walletid","savingaccountid","accounttype","currency","balance","limitamount")
    SELECT ${walletId}, NULL, 'SavingAccount', 'SAR', 0, 0
    WHERE NOT EXISTS (
      SELECT 1 FROM "Account"
      WHERE "walletid" = ${walletId} AND "accounttype" = 'SavingAccount'
    )
  `;

  // Ensure SpendingAccount
  await s`
    INSERT INTO "Account"("walletid","savingaccountid","accounttype","currency","balance","limitamount")
    SELECT ${walletId}, NULL, 'SpendingAccount', 'SAR', 0, 0
    WHERE NOT EXISTS (
      SELECT 1 FROM "Account"
      WHERE "walletid" = ${walletId} AND "accounttype" = 'SpendingAccount'
    )
  `;

  const accounts = await s`
    SELECT "accountid","accounttype"
    FROM "Account"
    WHERE "walletid" = ${walletId}
      AND "accounttype" IN ('SavingAccount','SpendingAccount')
  `;

  let savingAccountId = null;
  let spendingAccountId = null;
  for (const a of accounts) {
    if (a.accounttype === "SavingAccount") savingAccountId = a.accountid;
    if (a.accounttype === "SpendingAccount") spendingAccountId = a.accountid;
  }

  return { walletId, savingAccountId, spendingAccountId };
}

/**
 * POST /api/transfer
 * Body: { parentId, childId, amount, savePercentage }
 * Splits allowance into Saving + Spending accounts for the child.
 */
export const transferMoney = async (req, res) => {
  try {
    const { parentId, childId, amount, savePercentage } = req.body;

    if (!parentId || !childId || !amount || savePercentage == null) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const amt = Number(amount);
    const savePct = Number(savePercentage);

    if (amt <= 0) {
      return res.status(400).json({ error: "Amount must be > 0" });
    }
    if (savePct < 0 || savePct > 100) {
      return res.status(400).json({ error: "savePercentage must be between 0 and 100" });
    }

    const spendPct = 100 - savePct;
    const saveAmount = (savePct / 100) * amt;
    const spendAmount = (spendPct / 100) * amt;

    const out = await sql.begin(async (s) => {
      // 1) Parent wallet + ParentAccount
      const {
        parentAccountId,
        parentBalance,
      } = await ensureParentWalletAndAccount(parentId, s);

      if (parentBalance < amt) {
        return { error: "insufficient_balance" };
      }

      // 2) Child wallet + Saving / Spending accounts
      const {
        savingAccountId,
        spendingAccountId,
      } = await ensureChildWalletAndCoreAccounts(childId, s);

      if (!savingAccountId || !spendingAccountId) {
        return { error: "child_accounts_not_ready" };
      }

      // 3) Insert transactions (ParentAccount → SavingAccount / SpendingAccount)
      if (saveAmount > 0) {
        await s`
          INSERT INTO "Transaction"(
            "transactiontype","amount","transactiondate","transactionstatus",
            "merchantname","sourcetype","transactioncategory",
            "senderAccountId","receiverAccountId"
          )
          VALUES (
            'Transfer', ${saveAmount}, CURRENT_TIMESTAMP, 'Completed',
            'Parent Allowance', 'Allowance', 'Saving',
            ${parentAccountId}, ${savingAccountId}
          )
        `;
      }

      if (spendAmount > 0) {
        await s`
          INSERT INTO "Transaction"(
            "transactiontype","amount","transactiondate","transactionstatus",
            "merchantname","sourcetype","transactioncategory",
            "senderAccountId","receiverAccountId"
          )
          VALUES (
            'Transfer', ${spendAmount}, CURRENT_TIMESTAMP, 'Completed',
            'Parent Allowance', 'Allowance', 'Spending',
            ${parentAccountId}, ${spendingAccountId}
          )
        `;
      }

      // 4) Update balances
      await s`
        UPDATE "Account"
        SET "balance" = "balance" - ${amt}
        WHERE "accountid" = ${parentAccountId}
      `;
      if (saveAmount > 0) {
        await s`
          UPDATE "Account"
          SET "balance" = "balance" + ${saveAmount}
          WHERE "accountid" = ${savingAccountId}
        `;
      }
      if (spendAmount > 0) {
        await s`
          UPDATE "Account"
          SET "balance" = "balance" + ${spendAmount}
          WHERE "accountid" = ${spendingAccountId}
        `;
      }

      return {
        ok: true,
        transferred: amt,
        saveAmount,
        spendAmount,
      };
    });

    if (out?.error === "insufficient_balance") {
      return res.status(400).json({ error: "Insufficient parent balance" });
    }
    if (out?.error === "child_accounts_not_ready") {
      return res.status(500).json({ error: "Child accounts not ready" });
    }

    return res.json({
      message: "Transfer successful",
      transferred: out.transferred,
      saveAmount: out.saveAmount,
      spendAmount: out.spendAmount,
    });
  } catch (err) {
    console.error("❌ Transfer error:", err);
    res.status(500).json({ error: "Failed to transfer money" });
  }
};
