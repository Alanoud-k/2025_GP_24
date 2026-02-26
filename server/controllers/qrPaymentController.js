import { sql } from "../config/db.js";
import { generateToken, buildQrString } from "../utils/qrToken.js";

async function predictCategory(merchantName) {
  const mlUrl = process.env.ML_URL || "https://hassalah-ai.up.railway.app";
  const name = String(merchantName || "").trim();
  if (!name) return null;

  const r = await fetch(`${mlUrl}/predict`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ merchant_name: name }),
  });

  if (!r.ok) return null;

  const j = await r.json();
  return j?.predicted_category || j?.category || null;
}

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
      receiverAccountId,
    });
  } catch (e) {
    console.error("createQrRequest error:", e);
    return res.status(500).json({ error: "Server error creating QR request." });
  }
}

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

    const expiresAt = new Date(qr.expiresat);
    if (qr.status !== "PENDING") {
      return res.status(409).json({ error: `QR is not payable (status: ${qr.status}).` });
    }
    if (Date.now() > expiresAt.getTime()) {
      return res.status(409).json({ error: "QR request expired." });
    }

    return res.json({
      merchantname: qr.merchantname,
      amount: Number(qr.amount),
      expiresat: new Date(qr.expiresat).toISOString(),
      receiveraccountid: qr.receiveraccountid,
      status: qr.status,
    });
  } catch (e) {
    console.error("resolveQrToken error:", e);
    return res.status(500).json({ error: "Server error resolving QR token." });
  }
}

export async function confirmQrPayment(req, res) {
  try {
    const { token, childId } = req.body;

    if (!token || String(token).length < 10) {
      return res.status(400).json({ error: "Invalid token." });
    }
    if (!childId || !Number.isInteger(Number(childId))) {
      return res.status(400).json({ error: "childId is required." });
    }

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

    const limit = Number(sender.limitamount ?? 0);
    if (limit > 0 && amount > limit) {
      return res.status(403).json({ error: "Payment exceeds spending limit." });
    }

    if (senderBalance < amount) {
      return res.status(403).json({ error: "Insufficient balance." });
    }

    const category = (await predictCategory(qr.merchantname)) || "Uncategorized";
    const categorySource = category === "Uncategorized" ? null : "ML";

    const txnRows = await sql`
      INSERT INTO "Transaction"
        (transactiontype, amount, merchantname, "senderAccountId", "receiverAccountId", transactionstatus, sourcetype, transactioncategory, categorysource)
      VALUES
        ('Payment', ${amount}, ${qr.merchantname}, ${senderAccountId}, ${receiverAccountId}, 'Completed', 'QR', ${category}, ${categorySource})
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

    return res.json({ transactionId, category });
  } catch (e) {
    console.error("confirmQrPayment error:", e);
    return res.status(500).json({ error: "Server error confirming payment." });
  }
}