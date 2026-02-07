// server/controllers/qrPaymentController.js
import { sql } from "../config/db.js";
import { generateToken, buildQrString } from "../utils/qrToken.js";

/**
 * POST /api/qr/create
 * Body: { merchantName, amount, receiverAccountId?, expiresInMinutes? }
 * Returns: { token, qrString, expiresAt }
 *
 * Notes:
 * - For demo: if receiverAccountId is not provided, you MUST provide it
 *   OR choose a default merchant receiving account in DB.
 */
export async function createQrRequest(req, res) {
  try {
    const { merchantName, amount, expiresInMinutes } = req.body;

    if (!merchantName || String(merchantName).trim().length < 2) {
      return res.status(400).json({ error: "merchantName is required." });
    }

    const amt = Number(amount);
    if (!Number.isFinite(amt) || amt <= 0) {
      return res.status(400).json({ error: "amount must be > 0." });
    }

    // 1) Find merchant by name
    const mRows = await sql`
      SELECT merchantid, merchantname
      FROM "Merchant"
      WHERE LOWER(merchantname) = LOWER(${merchantName})
      LIMIT 1
    `;

    if (!mRows || mRows.length === 0) {
      return res.status(404).json({ error: "Merchant not found / cannot be verified." });
    }

    const merchantId = Number(mRows[0].merchantid);

    // 2) Find merchant wallet
    const wRows = await sql`
      SELECT walletid
      FROM "Wallet"
      WHERE merchantid = ${merchantId}
      LIMIT 1
    `;

    if (!wRows || wRows.length === 0) {
      return res.status(404).json({ error: "Merchant wallet not found." });
    }

    const walletId = Number(wRows[0].walletid);

    // 3) Find merchant receiving account
    const aRows = await sql`
      SELECT accountid
      FROM "Account"
      WHERE walletid = ${walletId}
        AND accounttype = 'MerchantAccount'
      LIMIT 1
    `;

    if (!aRows || aRows.length === 0) {
      return res.status(404).json({ error: "Merchant receiving account not found." });
    }

    const receiverAccountId = Number(aRows[0].accountid);

    // 4) Create QR request
    const token = generateToken();
    const mins = Number.isFinite(Number(expiresInMinutes)) ? Number(expiresInMinutes) : 10;
    const expiresAt = new Date(Date.now() + mins * 60 * 1000);

    await sql`
      INSERT INTO "QRPaymentRequest"
        (token, merchantname, amount, receiveraccountid, status, expiresat)
      VALUES
        (${token}, ${merchantName}, ${amt}, ${receiverAccountId}, 'PENDING', ${expiresAt.toISOString()})
    `;

    return res.json({
      token,
      qrString: buildQrString(token),
      expiresAt: expiresAt.toISOString(),
      receiverAccountId, // optional but useful for debugging
    });
  } catch (e) {
    console.error("createQrRequest error:", e);
    return res.status(500).json({ error: "Server error creating QR request." });
  }
}


/**
 * GET /api/qr/resolve?token=...
 * Returns minimal info for confirmation screen.
 */
export async function resolveQrToken(req, res) {
  try {
    const { token } = req.query;

    if (!token || String(token).length < 10) {
      return res.status(400).json({ error: "Invalid token." });
    }

    const rows = await sql`
      SELECT
        token,
        merchantname,
        amount,
        receiveraccountid,
        status,
        expiresat
      FROM "QRPaymentRequest"
      WHERE token = ${token}
      LIMIT 1
    `;

    if (!rows || rows.length === 0) {
      return res.status(404).json({ error: "QR request not found." });
    }

    const qr = rows[0];

    // Basic checks
    const expiresAt = new Date(qr.expiresat);
    if (qr.status !== "PENDING") {
      return res.status(409).json({ error: `QR is not payable (status: ${qr.status}).` });
    }
    if (Date.now() > expiresAt.getTime()) {
      return res.status(409).json({ error: "QR request expired." });
    }

    // Match Flutter keys you used: merchantname, amount, expiresat
    return res.json({
      merchantname: qr.merchantname,
      amount: Number(qr.amount),
      expiresat: new Date(qr.expiresat).toISOString(),
      receiveraccountid: qr.receiveraccountid, // optional
      status: qr.status,
    });
  } catch (e) {
    console.error("resolveQrToken error:", e);
    return res.status(500).json({ error: "Server error resolving QR token." });
  }
}

/**
 * POST /api/qr/confirm
 * Body: { token, childId }
 * Does:
 *  - validate QR request
 *  - find child's SpendingAccount
 *  - enforce sufficient balance (+ optional limit)
 *  - create Transaction row (type=Payment)
 *  - update balances
 *  - mark QR request PAID
 * Returns: { transactionId }
 */
export async function confirmQrPayment(req, res) {
  try {
    const { token, childId } = req.body;

    if (!token || String(token).length < 10) {
      return res.status(400).json({ error: "Invalid token." });
    }
    if (!childId || !Number.isInteger(Number(childId))) {
      return res.status(400).json({ error: "childId is required." });
    }

    // 1) Load QR request
    const qrRows = await sql`
      SELECT
        token,
        merchantname,
        amount,
        receiveraccountid,
        status,
        expiresat
      FROM "QRPaymentRequest"
      WHERE token = ${token}
      LIMIT 1
    `;

    if (!qrRows || qrRows.length === 0) {
      return res.status(404).json({ error: "QR request not found." });
    }

    const qr = qrRows[0];
    const expiresAt = new Date(qr.expiresat);

    if (qr.status !== "PENDING") {
      return res.status(409).json({ error: `QR is not payable (status: ${qr.status}).` });
    }
    if (Date.now() > expiresAt.getTime()) {
      return res.status(409).json({ error: "QR request expired." });
    }

    const amount = Number(qr.amount);
    const receiverAccountId = Number(qr.receiveraccountid);

    // 2) Find child's SpendingAccount (based on your schema: Wallet(childid) -> Account(walletid))
    const senderRows = await sql`
      SELECT a.accountid, a.balance, a.limitamount
      FROM "Wallet" w
      JOIN "Account" a ON a.walletid = w.walletid
      WHERE w.childid = ${Number(childId)}
        AND a.accounttype = 'SpendingAccount'
      LIMIT 1
    `;

    if (!senderRows || senderRows.length === 0) {
      return res.status(404).json({ error: "Child spending account not found." });
    }

    const sender = senderRows[0];
    const senderAccountId = Number(sender.accountid);
    const senderBalance = Number(sender.balance);

    // Optional: enforce limitamount (if you mean "max allowed per payment")
    const limit = Number(sender.limitamount ?? 0);
    if (limit > 0 && amount > limit) {
      return res.status(403).json({ error: "Payment exceeds spending limit." });
    }

    if (senderBalance < amount) {
      return res.status(403).json({ error: "Insufficient balance." });
    }

    // 3) Update balances + create transaction + mark QR paid
    // Neon serverless often supports multi statements; if it doesn’t in your env,
    // we’ll refactor to safer steps. Start with this simplest version.
    const txnRows = await sql`
      INSERT INTO "Transaction"
        (transactiontype, amount, merchantname, senderaccountid, receiveraccountid, transactionstatus, sourcetype)
      VALUES
        ('Payment', ${amount}, ${qr.merchantname}, ${senderAccountId}, ${receiverAccountId}, 'Completed', 'QR')
      RETURNING transactionid
    `;

    const transactionId = txnRows?.[0]?.transactionid;

    await sql`
      UPDATE "Account"
      SET balance = balance - ${amount}
      WHERE accountid = ${senderAccountId}
    `;

    await sql`
      UPDATE "Account"
      SET balance = balance + ${amount}
      WHERE accountid = ${receiverAccountId}
    `;

    await sql`
      UPDATE "QRPaymentRequest"
      SET status = 'PAID', paidat = NOW()
      WHERE token = ${token}
    `;

    return res.json({ transactionId });
  } catch (e) {
    console.error("confirmQrPayment error:", e);
    return res.status(500).json({ error: "Server error confirming payment." });
  }
}