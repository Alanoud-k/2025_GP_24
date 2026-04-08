import { sql } from "../config/db.js";
import { generateToken, buildQrString } from "../utils/qrToken.js";
import keywordMap from "../ml_service/keywordMap.js";

async function predictCategory(merchantName) {
  const name = String(merchantName || "").trim();
  if (!name) return { category: null, source: null };

  const keywordCategory = keywordMap(name);
  if (keywordCategory) {
    console.log(`[QR ML] Categorized by keyword: ${keywordCategory}`);
    return { category: keywordCategory, source: "KEYWORD" };
  }

  try {
    const mlUrl = process.env.ML_URL || "https://hassalah-ai.up.railway.app";

    const r = await fetch(`${mlUrl}/predict`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ merchant_name: name }),
    });

    if (r.ok) {
      const j = await r.json();
      const predicted = j?.predicted_category || j?.category || null;

      if (predicted) {
        console.log(`[QR ML] Categorized by ML: ${predicted}`);
        return { category: predicted, source: "ML" };
      }
    }
  } catch (error) {
    console.error("[QR ML] Prediction failed:", error);
  }

  return { category: null, source: null };
}

export async function createQrRequest(req, res) {
  try {
    const rawMerchantName = String(req.body?.merchantName || "");
    const merchantName = rawMerchantName.trim();
    const amount = Number(req.body?.amount);
    const expiresInMinutes = Number(req.body?.expiresInMinutes);

    if (merchantName.length < 2) {
      return res.status(400).json({ error: "merchantName is required." });
    }

    if (!Number.isFinite(amount) || amount <= 0) {
      return res.status(400).json({ error: "amount must be > 0." });
    }

    const mins =
      Number.isFinite(expiresInMinutes) && expiresInMinutes > 0
        ? expiresInMinutes
        : 60;

    console.log("[QR CREATE] merchantName:", merchantName);
    console.log("[QR CREATE] amount:", amount);
    console.log("[QR CREATE] expiresInMinutes:", mins);

    const mRows = await sql`
      SELECT merchantid, merchantname
      FROM "Merchant"
      WHERE LOWER(TRIM(merchantname)) = LOWER(TRIM(${merchantName}))
      LIMIT 1
    `;

    if (!mRows || mRows.length === 0) {
      console.log("[QR CREATE] Merchant not found:", merchantName);
      return res
        .status(404)
        .json({ error: "Merchant not found / cannot be verified." });
    }

    const merchantId = Number(mRows[0].merchantid);
    const canonicalMerchantName = String(mRows[0].merchantname || merchantName);

    console.log("[QR CREATE] merchantRow:", mRows[0]);

    const wRows = await sql`
      SELECT walletid, walletstatus
      FROM "Wallet"
      WHERE merchantid = ${merchantId}
      LIMIT 1
    `;

    if (!wRows || wRows.length === 0) {
      console.log("[QR CREATE] Wallet not found for merchantId:", merchantId);
      return res.status(404).json({ error: "Merchant wallet not found." });
    }

    const walletId = Number(wRows[0].walletid);

    console.log("[QR CREATE] walletRow:", wRows[0]);

    const aRows = await sql`
      SELECT accountid, accounttype
      FROM "Account"
      WHERE walletid = ${walletId}
        AND accounttype = 'MerchantAccount'
      LIMIT 1
    `;

    if (!aRows || aRows.length === 0) {
      console.log("[QR CREATE] Merchant account not found for walletId:", walletId);
      return res
        .status(404)
        .json({ error: "Merchant receiving account not found." });
    }

    const receiverAccountId = Number(aRows[0].accountid);

    console.log("[QR CREATE] accountRow:", aRows[0]);
    console.log("[QR CREATE] receiverAccountId:", receiverAccountId);

    const token = generateToken();
    const expiresAt = new Date(Date.now() + mins * 60 * 1000);

    await sql`
      INSERT INTO "QRPaymentRequest"
        (token, merchantname, amount, receiveraccountid, status, expiresat)
      VALUES
        (
          ${token},
          ${canonicalMerchantName},
          ${amount},
          ${receiverAccountId},
          'PENDING',
          ${expiresAt}
        )
    `;

    console.log("[QR CREATE] Inserted successfully:", {
      token,
      canonicalMerchantName,
      amount,
      receiverAccountId,
      expiresAt: expiresAt.toISOString(),
    });

    return res.status(200).json({
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
    const token = String(req.query?.token || "").trim();

    console.log("[QR RESOLVE] token:", token);

    if (!token || token.length < 10) {
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
      console.log("[QR RESOLVE] QR request not found for token:", token);
      return res.status(404).json({ error: "QR request not found." });
    }

    const qr = rows[0];

    console.log("[QR RESOLVE] row:", qr);

    if (!qr.receiveraccountid) {
      return res.status(409).json({ error: "QR receiver account is missing." });
    }

    const expiresAt = new Date(qr.expiresat);

    if (Number.isNaN(expiresAt.getTime())) {
      return res.status(500).json({ error: "Invalid QR expiration date." });
    }

    if (qr.status !== "PENDING") {
      return res
        .status(409)
        .json({ error: `QR is not payable (status: ${qr.status}).` });
    }

    if (Date.now() > expiresAt.getTime()) {
      return res.status(409).json({ error: "QR request expired." });
    }

    return res.status(200).json({
      merchantname: qr.merchantname,
      amount: Number(qr.amount),
      expiresat: expiresAt.toISOString(),
      receiveraccountid: Number(qr.receiveraccountid),
      status: qr.status,
    });
  } catch (e) {
    console.error("resolveQrToken error:", e);
    return res.status(500).json({ error: "Server error resolving QR token." });
  }
}

export async function confirmQrPayment(req, res) {
  try {
    const token = String(req.body?.token || "").trim();
    const childId = Number(req.body?.childId);

    console.log("[QR CONFIRM] token:", token);
    console.log("[QR CONFIRM] childId:", childId);

    if (!token || token.length < 10) {
      return res.status(400).json({ error: "Invalid token." });
    }

    if (!Number.isInteger(childId) || childId <= 0) {
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

    console.log("[QR CONFIRM] qrRow:", qr);

    if (!qr.receiveraccountid) {
      return res.status(409).json({ error: "QR receiver account is missing." });
    }

    const expiresAt = new Date(qr.expiresat);

    if (qr.status !== "PENDING") {
      return res
        .status(409)
        .json({ error: `QR is not payable (status: ${qr.status}).` });
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
      WHERE w.childid = ${childId}
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

    console.log("[QR CONFIRM] senderRow:", sender);

    if (limit > 0 && amount > limit) {
      return res.status(403).json({ error: "Payment exceeds spending limit." });
    }

    if (senderBalance < amount) {
      return res.status(403).json({ error: "Insufficient balance." });
    }

    const prediction = await predictCategory(qr.merchantname);
    const category = prediction.category || "Uncategorized";
    const categorySource = prediction.source;

    const txnRows = await sql`
      INSERT INTO "Transaction"
        (
          transactiontype,
          amount,
          merchantname,
          "senderAccountId",
          "receiverAccountId",
          transactionstatus,
          sourcetype,
          transactioncategory,
          categorysource
        )
      VALUES
        (
          'Payment',
          ${amount},
          ${qr.merchantname},
          ${senderAccountId},
          ${receiverAccountId},
          'Completed',
          'QR',
          ${category},
          ${categorySource}
        )
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

    console.log("[QR CONFIRM] Payment success:", {
      transactionId,
      senderAccountId,
      receiverAccountId,
      amount,
      category,
      categorySource,
    });

    return res.status(200).json({
      transactionId,
      category,
      categorySource,
    });
  } catch (e) {
    console.error("confirmQrPayment error:", e);
    return res.status(500).json({ error: "Server error confirming payment." });
  }
}