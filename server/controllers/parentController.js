// server/controllers/parentController.js  (ESM)

import { sql } from "../config/db.js";
import bcrypt from "bcrypt";
import { getChildrenByParent as childGetChildrenByParent } from "./childController.js";

/* =====================================================
   Get Parent Info by ID (basic profile)
===================================================== */
export const getParentInfo = async (req, res) => {
  try {
    const { parentId } = req.params;

    const result = await sql`
      SELECT "firstname", "lastname", "phoneno", "nationalid"
      FROM "Parent"
      WHERE "parentid" = ${parentId}
      LIMIT 1
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: "Parent not found" });
    }

    const parent = result[0];

    return res.json({
      firstName: parent.firstname,
      lastName: parent.lastname,
      phoneNo: parent.phoneno,
      nationalId: parent.nationalid,
    });
  } catch (err) {
    console.error("❌ Error fetching parent info:", err);
    return res.status(500).json({
      error: "Failed to fetch parent info",
      details: err.message,
    });
  }
};

/* =====================================================
   Get Children by Parent ID (REUSES childController)
   If any existing routes still import parentController.getChildrenByParent,
   they will now receive the enriched version from childController.
===================================================== */
export const getChildrenByParent = childGetChildrenByParent;

/* =====================================================
   Change Parent Password
===================================================== */
export const changeParentPassword = async (req, res) => {
  try {
    const { parentId } = req.params;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        error: "Current password and new password are required",
      });
    }

    const parentResult = await sql`
      SELECT "password"
      FROM "Parent"
      WHERE "parentid" = ${parentId}
    `;

    if (parentResult.length === 0) {
      return res.status(404).json({ error: "Parent not found" });
    }

    const storedHashedPassword = parentResult[0].password;
    const isPasswordValid = await bcrypt.compare(
      currentPassword,
      storedHashedPassword
    );

    if (!isPasswordValid) {
      return res.status(401).json({ error: "Current password is incorrect" });
    }

    const newHashedPassword = await bcrypt.hash(newPassword, 10);

    await sql`
      UPDATE "Parent"
      SET "password" = ${newHashedPassword}
      WHERE "parentid" = ${parentId}
    `;

    return res.json({ message: "Password changed successfully" });
  } catch (err) {
    console.error("❌ Error changing parent password:", err);
    return res.status(500).json({
      error: "Failed to change password",
      details: err.message,
    });
  }
};

/* =====================================================
   Change Child Password (from parent area)
===================================================== */
export const changeChildPassword = async (req, res) => {
  try {
    const { childId } = req.params;
    const { newPassword } = req.body;

    if (!newPassword) {
      return res.status(400).json({ error: "New password is required" });
    }

    const childResult = await sql`
      SELECT "childid"
      FROM "Child"
      WHERE "childid" = ${childId}
      LIMIT 1
    `;

    if (childResult.length === 0) {
      return res.status(404).json({ error: "Child not found" });
    }

    const saltRounds = 10;
    const newHashedPassword = await bcrypt.hash(newPassword, saltRounds);

    await sql`
      UPDATE "Child"
      SET "password" = ${newHashedPassword}
      WHERE "childid" = ${childId}
    `;

    return res.json({ message: "Child password changed successfully" });
  } catch (err) {
    console.error("❌ Error changing child password:", err);
    return res.status(500).json({
      error: "Failed to change child password",
      details: err.message,
    });
  }
};

/* =====================================================
   Get Parent Wallet (ParentAccount)
===================================================== */
export const getParentWallet = async (req, res) => {
  try {
    const { parentId } = req.params;

    // Find parent wallet
    const wallets = await sql`
      SELECT "walletid"
      FROM "Wallet"
      WHERE "parentid" = ${parentId}
      LIMIT 1
    `;
    if (wallets.length === 0) {
      return res
        .status(404)
        .json({ error: "Wallet not found for this parent" });
    }
    const walletId = wallets[0].walletid;

    // Find ParentAccount under this wallet
    const accounts = await sql`
      SELECT "accountid", "balance"
      FROM "Account"
      WHERE "walletid" = ${walletId}
        AND "accounttype" = 'ParentAccount'
      LIMIT 1
    `;
    if (accounts.length === 0) {
      return res
        .status(404)
        .json({ error: "Parent account not found for this wallet" });
    }

    const account = accounts[0];

    return res.json({
      accountId: account.accountid,
      balance: Number(account.balance ?? 0),
    });
  } catch (err) {
    console.error("❌ Error fetching parent wallet:", err);
    return res.status(500).json({
      error: "Failed to fetch parent wallet",
      details: err.message,
    });
  }
};

/* =====================================================
   Get Parent Transactions (recent operations)
===================================================== */
export const getParentTransactions = async (req, res) => {
  try {
    const { parentId } = req.params;
    const limit = Number(req.query.limit) || 10;

    // Wallet → ParentAccount
    const wallets = await sql`
      SELECT "walletid"
      FROM "Wallet"
      WHERE "parentid" = ${parentId}
      LIMIT 1
    `;
    if (wallets.length === 0) {
      return res
        .status(404)
        .json({ error: "Wallet not found for this parent" });
    }
    const walletId = wallets[0].walletid;

    const accounts = await sql`
      SELECT "accountid"
      FROM "Account"
      WHERE "walletid" = ${walletId}
        AND "accounttype" = 'ParentAccount'
      LIMIT 1
    `;
    if (accounts.length === 0) {
      return res
        .status(404)
        .json({ error: "Parent account not found for this wallet" });
    }
    const accountId = accounts[0].accountid;

    const transactions = await sql`
      SELECT
        "transactionid",
        "transactiontype",
        "amount",
        "transactiondate",
        "transactionstatus",
        "merchantname",
        "transactioncategory"
      FROM "Transaction"
      WHERE "receiverAccountId" = ${accountId}
         OR "senderAccountId"   = ${accountId}
      ORDER BY "transactiondate" DESC
      LIMIT ${limit}
    `;

    return res.json({
      accountId,
      transactions: transactions.map((tx) => ({
        id: tx.transactionid,
        type: tx.transactiontype,
        amount: Number(tx.amount ?? 0),
        date: tx.transactiondate,
        status: tx.transactionstatus,
        merchantName: tx.merchantname,
        category: tx.transactioncategory,
      })),
    });
  } catch (err) {
    console.error("❌ Error fetching parent transactions:", err);
    return res.status(500).json({
      error: "Failed to fetch parent transactions",
      details: err.message,
    });
  }
};
