// controllers/transferController.js
const { sql } = require("../config/db");

exports.transferMoney = async (req, res) => {
  try {
    const { parentId, childId, amount, savePercentage } = req.body;

    if (!parentId || !childId || !amount || savePercentage == null)
      return res.status(400).json({ error: "Missing required fields" });

    const spendPercentage = 100 - savePercentage;
    const saveAmount = (savePercentage / 100) * amount;
    const spendAmount = (spendPercentage / 100) * amount;

    // ✅ Get parent wallet
    const parentWallet = await sql`
      SELECT walletBalance FROM "Wallet" WHERE parentId = ${parentId}
    `;
    if (parentWallet.length === 0)
      return res.status(404).json({ error: "Parent wallet not found" });

    const currentBalance = parentWallet[0].walletbalance;
    if (currentBalance < amount)
      return res.status(400).json({ error: "Insufficient balance" });

    // ✅ Deduct from parent
    await sql`
      UPDATE "Wallet"
      SET walletBalance = walletBalance - ${amount}
      WHERE parentId = ${parentId}
    `;

    // ✅ Add to child wallet
    await sql`
      UPDATE "Wallet"
      SET walletBalance = walletBalance + ${amount}
      WHERE childId = ${childId}
    `;

    // ✅ Get or create BalanceBreakdown
    const wallet = await sql`
      SELECT walletId FROM "Wallet" WHERE childId = ${childId}
    `;
    if (wallet.length === 0)
      return res.status(404).json({ error: "Child wallet not found" });

    const walletId = wallet[0].walletid;

    const existing = await sql`
      SELECT * FROM "BalanceBreakdown" WHERE walletId = ${walletId}
    `;

    if (existing.length > 0) {
  await sql`
    UPDATE "BalanceBreakdown"
    SET 
      savedamount = savedamount + ${saveAmount},
      spendamount = spendamount + ${spendAmount}
    WHERE walletId = ${walletId}
  `;
} else {
  await sql`
    INSERT INTO "BalanceBreakdown" (walletId, savedamount, spendamount, limitamount)
    VALUES (${walletId}, ${saveAmount}, ${spendAmount}, 0)
  `;
}


    res.json({
      message: "Transfer successful",
      transferred: amount,
      saveAmount,
      spendAmount,
    });
  } catch (err) {
    console.error("❌ Transfer error:", err);
    res.status(500).json({ error: "Failed to transfer money" });
  }
};
