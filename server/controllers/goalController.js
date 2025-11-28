import { sql } from "../config/db.js";

/* -------------------------------------------------
   Helpers
--------------------------------------------------*/

// Ensure the child has a wallet and return walletid
async function ensureWallet(childId) {
  const w = await sql`
    SELECT walletid FROM "Wallet"
    WHERE childid = ${childId}
    LIMIT 1
  `;
  if (w.length) return w[0].walletid;

  const ins = await sql`
    INSERT INTO "Wallet"(parentid, childid, walletstatus)
    VALUES (NULL, ${childId}, 'Active')
    RETURNING walletid
  `;
  return ins[0].walletid;
}

// Ensure SavingAccount + SpendingAccount exist
async function ensureCoreAccounts(walletId) {
  await sql`
    INSERT INTO "Account"(walletid, savingaccountid, accounttype, currency, balance, limitamount)
    SELECT ${walletId}, NULL, 'SavingAccount', 'SAR', 0, 0
    WHERE NOT EXISTS (
      SELECT 1 FROM "Account"
      WHERE walletid = ${walletId} AND accounttype = 'SavingAccount'
    )
  `;

  await sql`
    INSERT INTO "Account"(walletid, savingaccountid, accounttype, currency, balance, limitamount)
    SELECT ${walletId}, NULL, 'SpendingAccount', 'SAR', 0, 0
    WHERE NOT EXISTS (
      SELECT 1 FROM "Account"
      WHERE walletid = ${walletId} AND accounttype = 'SpendingAccount'
    )
  `;
}

/* -------------------------------------------------
   Routes
--------------------------------------------------*/

// SETUP CHILD WALLET
export async function setupChildWallet(req, res) {
  try {
    const childId = Number(req.params.childId);
    const walletId = await ensureWallet(childId);
    await ensureCoreAccounts(walletId);

    return res.status(201).json({ walletId });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "wallet_setup_failed" });
  }
}

// LIST GOALS
export async function listChildGoals(req, res) {
  try {
    const childId = Number(req.params.childId);

    const rows = await sql`
      SELECT
        g.goalid,
        g.goalname,
        g.targetamount,
        g.goalstatus,
        g.description,
        a.balance
      FROM "Goal" g
      JOIN "Account" a ON a.accountid = g.accountid
      WHERE g.childid = ${childId}
      ORDER BY g.goalid DESC
    `;

    return res.json(rows);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "list_goals_failed" });
  }
}

// GET GOAL BY ID
export async function getGoalById(req, res) {
  try {
    const goalId = Number(req.params.goalId);

    const g = await sql`
      SELECT
        g.goalid,
        g.goalname,
        g.targetamount,
        g.goalstatus,
        g.description,
        a.balance
      FROM "Goal" g
      JOIN "Account" a ON a.accountid = g.accountid
      WHERE g.goalid = ${goalId}
      LIMIT 1
    `;

    if (!g.length) return res.status(404).json({ error: "goal_not_found" });

    return res.json(g[0]);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "get_goal_failed" });
  }
}

// CREATE GOAL
export async function createGoal(req, res) {
  try {
    const { childId, goalName, targetAmount, description } = req.body;

    if (!childId || !goalName || targetAmount == null)
      return res.status(400).json({ error: "missing_fields" });

    const walletId = await ensureWallet(childId);
    await ensureCoreAccounts(walletId);

    const sav = await sql`
      SELECT accountid FROM "Account"
      WHERE walletid = ${walletId} AND accounttype = 'SavingAccount'
      LIMIT 1
    `;

    if (!sav.length) {
      return res.status(500).json({ error: "saving_account_missing" });
    }

    const savingAccountId = sav[0].accountid;

    // Create Goal Account
    const gacc = await sql`
      INSERT INTO "Account"(walletid, savingaccountid, accounttype, currency, balance, limitamount)
      VALUES (${walletId}, ${savingAccountId}, 'GoalAccount', 'SAR', 0, 0)
      RETURNING accountid
    `;

    const goalAccId = gacc[0].accountid;

    // Create Goal
    const g = await sql`
      INSERT INTO "Goal"(childid, accountid, goalname, targetamount, goalstatus, description)
      VALUES (${childId}, ${goalAccId}, ${goalName}, ${targetAmount}, 'InProgress', ${description})
      RETURNING *
    `;

    return res.status(201).json(g[0]);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "create_goal_failed" });
  }
}

// UPDATE GOAL
export async function updateGoal(req, res) {
  try {
    const goalId = Number(req.params.goalId);
    const { goalName, targetAmount, description } = req.body;

    await sql`
      UPDATE "Goal"
      SET goalname = ${goalName},
          targetamount = ${targetAmount},
          description = ${description}
      WHERE goalid = ${goalId}
    `;

    return res.json({ ok: true });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "update_goal_failed" });
  }
}

/* -------------------------------------------------
   ADD MONEY TO GOAL  (Saving → Goal)
--------------------------------------------------*/
export async function addMoneyToGoal(req, res) {
  try {
    const goalId = Number(req.params.goalId);
    const { childId, amount } = req.body;
    const amt = Number(amount);

    if (!amt || amt <= 0)
      return res.status(400).json({ error: "invalid_amount" });

    // Fetch goal + accounts
    const g = await sql`
      SELECT g.targetamount, a.accountid AS goalaccountid, a.savingaccountid
      FROM "Goal" g
      JOIN "Account" a ON a.accountid = g.accountid
      WHERE g.goalid = ${goalId} AND g.childid = ${childId}
      LIMIT 1
    `;

    if (!g.length) return res.status(404).json({ error: "goal_not_found" });

    const targetAmount = Number(g[0].targetamount);
    const goalAcc = g[0].goalaccountid;
    const saveAcc = g[0].savingaccountid;

    // Get current goal balance
    const [goalBalRow] = await sql`
      SELECT balance FROM "Account" WHERE accountid = ${goalAcc}
    `;
    const currentGoalBalance = Number(goalBalRow.balance);
    const remaining = targetAmount - currentGoalBalance;

    // Do not allow adding more than needed
    if (amt > remaining) {
      return res.status(400).json({
        error: "exceeds_goal_limit",
        message: `Goal only needs ${remaining} SAR to complete.`,
      });
    }

    // Check saving balance
    const [sBal] = await sql`
      SELECT balance FROM "Account" WHERE accountid = ${saveAcc}
    `;
    if (Number(sBal.balance) < amt) {
      return res.status(400).json({
        error: "insufficient_saving",
        message: "Not enough money in Saving balance.",
      });
    }

    // Withdraw from saving
    await sql`
      UPDATE "Account" SET balance = balance - ${amt}
      WHERE accountid = ${saveAcc}
    `;

    // Deposit into goal
    const [updated] = await sql`
      UPDATE "Account" SET balance = balance + ${amt}
      WHERE accountid = ${goalAcc}
      RETURNING balance
    `;

    const newGoalBalance = Number(updated.balance);

    // If completed → update status
    if (newGoalBalance >= targetAmount) {
      await sql`
        UPDATE "Goal" SET goalstatus = 'Achieved'
        WHERE goalid = ${goalId}
      `;
    }

    return res.json({
      ok: true,
      message: "Money added to goal",
      newGoalBalance,
    });
  } catch (err) {
    console.error("goal_move_in_failed:", err);
    return res.status(500).json({ error: "goal_move_in_failed" });
  }
}

/* -------------------------------------------------
   MOVE MONEY OUT OF GOAL (Goal → Saving)
--------------------------------------------------*/
export async function moveMoneyFromGoal(req, res) {
  try {
    const goalId = Number(req.params.goalId);
    const { childId, amount } = req.body;
    const amt = Number(amount);

    if (!amt || amt <= 0)
      return res.status(400).json({ error: "invalid_amount" });

    const g = await sql`
      SELECT a.accountid AS goalaccountid, a.savingaccountid
      FROM "Goal" g
      JOIN "Account" a ON a.accountid = g.accountid
      WHERE g.goalid = ${goalId} AND g.childid = ${childId}
      LIMIT 1
    `;

    if (!g.length) return res.status(404).json({ error: "goal_not_found" });

    const goalAcc = g[0].goalaccountid;
    const saveAcc = g[0].savingaccountid;

    const [goalBal] = await sql`
      SELECT balance FROM "Account" WHERE accountid = ${goalAcc}
    `;

    if (Number(goalBal.balance) < amt) {
      return res.status(400).json({
        error: "insufficient_goal_balance",
        message: "Not enough money inside this goal.",
      });
    }

    // Move money out
    await sql`UPDATE "Account" SET balance = balance - ${amt} WHERE accountid = ${goalAcc}`;
    const [newSave] = await sql`
      UPDATE "Account" SET balance = balance + ${amt}
      WHERE accountid = ${saveAcc}
      RETURNING balance
    `;

    return res.json({
      ok: true,
      newSavingBalance: newSave.balance,
    });
  } catch (err) {
    console.error("goal_move_out_failed:", err);
    return res.status(500).json({ error: "goal_move_out_failed" });
  }
}


// DELETE GOAL
export async function deleteGoal(req, res) {
  try {
    const goalId = Number(req.params.goalId);

    const g = await sql`
      SELECT ga.accountid, ga.balance
      FROM "Goal" g
      JOIN "Account" ga ON ga.accountid = g.accountid
      WHERE g.goalid = ${goalId}
      LIMIT 1
    `;

    if (!g.length) return res.status(404).json({ error: "goal_not_found" });

    if (Number(g[0].balance) > 0)
      return res.status(400).json({ error: "goal_has_money" });

    // Delete goal + account
    await sql`DELETE FROM "Goal" WHERE goalid = ${goalId}`;
    await sql`DELETE FROM "Account" WHERE accountid = ${g[0].accountid}`;

    return res.json({ ok: true });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "delete_goal_failed" });
  }
}

// GET WALLET BALANCES (Saving + Spending)
export async function getChildWalletBalances(req, res) {
  try {
    const childId = Number(req.params.childId);
    if (!childId) {
      return res.status(400).json({ error: "invalid_child" });
    }

    console.log("➡ Fetching balances for child", childId);

    // 1) Ensure wallet exists
    const walletId = await ensureWallet(childId);
    await ensureCoreAccounts(walletId);

    console.log("   walletId =", walletId);

    // 2) Get Saving balance
    const [sav] = await sql`
      SELECT COALESCE(SUM(balance), 0)::float AS saving
      FROM "Account"
      WHERE walletid = ${walletId}
        AND accounttype = 'SavingAccount'
    `;

    // 3) Get Spending balance
    const [sp] = await sql`
      SELECT COALESCE(SUM(balance), 0)::float AS spending
      FROM "Account"
      WHERE walletid = ${walletId}
        AND accounttype = 'SpendingAccount'
    `;

    const saving = Number(sav?.saving ?? 0);
    const spending = Number(sp?.spending ?? 0);

    console.log("   saving =", saving, "| spending =", spending);

    return res.json({
      saving,
      spending,
      total: saving + spending,
    });
  } catch (err) {
    console.error("❌ balance_fetch_failed:", err);
    return res.status(500).json({ error: "balance_fetch_failed" });
  }
}

/* -------------------------------------------------
   SPENDING → SAVING   (move-in)
--------------------------------------------------*/

export async function moveInSaving(req, res) {
  try {
    const { childId, amount } = req.body;
    const amt = Number(amount);

    const walletId = await ensureWallet(childId);
    await ensureCoreAccounts(walletId);

    const [spending] = await sql`
      SELECT accountid, balance FROM "Account"
      WHERE walletid = ${walletId} AND accounttype = 'SpendingAccount'
    `;

    const [saving] = await sql`
      SELECT accountid, balance FROM "Account"
      WHERE walletid = ${walletId} AND accounttype = 'SavingAccount'
    `;

    if (!spending || !saving)
      return res.status(400).json({ error: "accounts_missing" });

    if (Number(spending.balance) < amt)
      return res.status(400).json({ error: "insufficient_spending" });

    await sql`
      UPDATE "Account"
      SET balance = balance - ${amt}
      WHERE accountid = ${spending.accountid}
    `;

    await sql`
      UPDATE "Account"
      SET balance = balance + ${amt}
      WHERE accountid = ${saving.accountid}
    `;

    return res.json({ ok: true });
  } catch (err) {
    console.error("move_in_failed:", err);
    return res.status(500).json({ error: "move_in_failed" });
  }
}

/* -------------------------------------------------
   SAVING → SPENDING  (move-out)
--------------------------------------------------*/

export async function moveOutSaving(req, res) {
  try {
    const { childId, amount } = req.body;
    const amt = Number(amount);

    const walletId = await ensureWallet(childId);
    await ensureCoreAccounts(walletId);

    const [saving] = await sql`
      SELECT accountid, balance FROM "Account"
      WHERE walletid = ${walletId} AND accounttype = 'SavingAccount'
    `;

    const [spending] = await sql`
      SELECT accountid, balance FROM "Account"
      WHERE walletid = ${walletId} AND accounttype = 'SpendingAccount'
    `;

    if (!saving || !spending)
      return res.status(400).json({ error: "accounts_missing" });

    if (Number(saving.balance) < amt)
      return res.status(400).json({ error: "insufficient_saving" });

    await sql`
      UPDATE "Account"
      SET balance = balance - ${amt}
      WHERE accountid = ${saving.accountid}
    `;

    await sql`
      UPDATE "Account"
      SET balance = balance + ${amt}
      WHERE accountid = ${spending.accountid}
    `;

    return res.json({ ok: true });
  } catch (err) {
    console.error("move_out_failed:", err);
    return res.status(500).json({ error: "move_out_failed" });
  }
}

/* -------------------------------------------------
   NEW: REDEEM COMPLETED GOAL → TRANSFER TO SPENDING
--------------------------------------------------*/
export async function redeemGoal(req, res) {
  try {
    const goalId = Number(req.params.goalId);
    const { childId } = req.body;

    // Load goal + account
    const g = await sql`
      SELECT g.goalstatus, a.accountid AS goalaccountid, a.savingaccountid, a.walletid
      FROM "Goal" g
      JOIN "Account" a ON a.accountid = g.accountid
      WHERE g.goalid = ${goalId} AND g.childid = ${childId}
      LIMIT 1
    `;

    if (!g.length) return res.status(404).json({ error: "goal_not_found" });

    if (g[0].goalstatus !== "Achieved") {
      return res.status(400).json({ error: "goal_not_completed" });
    }

    const walletId = g[0].walletid;

    const [spending] = await sql`
      SELECT accountid FROM "Account"
      WHERE walletid = ${walletId} AND accounttype = 'SpendingAccount'
      LIMIT 1
    `;

    const goalAcc = g[0].goalaccountid;

    const [goalBal] = await sql`
      SELECT balance FROM "Account" WHERE accountid = ${goalAcc}
    `;

    const amt = Number(goalBal.balance);

    // Empty goal balance
    await sql`
      UPDATE "Account" SET balance = 0 WHERE accountid = ${goalAcc}
    `;

    // Add into spending account
    const [newSpend] = await sql`
      UPDATE "Account"
      SET balance = balance + ${amt}
      WHERE accountid = ${spending.accountid}
      RETURNING balance
    `;

    return res.json({
      ok: true,
      transferred: amt,
      newSpendingBalance: newSpend.balance,
    });
  } catch (err) {
    console.error("redeem_goal_failed:", err);
    return res.status(500).json({ error: "redeem_goal_failed" });
  }
}