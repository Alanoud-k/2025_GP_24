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

    const cId = Number(childId);
    const amt = Number(amount);

    if (!cId || !amt || amt <= 0) {
      return res.status(400).json({ error: "invalid_fields" });
    }

    const rows = await sql`
      SELECT
        g.goalid,
        g.goalstatus,
        g.targetamount,
        a.accountid       AS goalaccountid,
        a.balance         AS goalbalance,
        a.savingaccountid AS savingaccountid
      FROM "Goal" g
      JOIN "Account" a ON a.accountid = g.accountid
      WHERE g.goalid = ${goalId} AND g.childid = ${cId}
      LIMIT 1
    `;

    if (!rows.length) {
      return res.status(404).json({ error: "goal_not_found" });
    }

    const row = rows[0];
    const goalStatus = row.goalstatus;
    const targetAmount = Number(row.targetamount);
    const goalBalance = Number(row.goalbalance);
    const goalAccId = row.goalaccountid;
    const savingAccId = row.savingaccountid;

    // ❌ No more contributions if achieved
    if (goalStatus === "Achieved") {
      return res.status(400).json({
        error: "goal_completed_no_more_contributions",
      });
    }

    // ❌ Do not allow going above target
    const newGoalBalance = goalBalance + amt;
    if (newGoalBalance > targetAmount) {
      return res.status(400).json({
        error: "over_target",
        message: "Cannot exceed goal target amount.",
      });
    }

    // Check saving balance
    const [sBal] = await sql`
      SELECT balance FROM "Account" WHERE accountid = ${savingAccId}
    `;
    const savingBalance = Number(sBal?.balance ?? 0);

    if (savingBalance < amt) {
      return res.status(400).json({ error: "insufficient_saving" });
    }

    // Transfer: Saving → Goal
    await sql`
      UPDATE "Account"
      SET balance = balance - ${amt}
      WHERE accountid = ${savingAccId}
    `;

    const [updGoal] = await sql`
      UPDATE "Account"
      SET balance = balance + ${amt}
      WHERE accountid = ${goalAccId}
      RETURNING balance
    `;

    const finalGoalBalance = Number(updGoal.balance);

    // ⭐ If we hit target, mark as Achieved (and keep it that way)
    if (finalGoalBalance >= targetAmount) {
      await sql`
        UPDATE "Goal"
        SET goalstatus = 'Achieved'
        WHERE goalid = ${goalId}
      `;
    }

    return res.json({
      ok: true,
      goalId,
      newGoalBalance: finalGoalBalance,
    });
  } catch (err) {
    console.error(err);
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

    const cId = Number(childId);
    const amt = Number(amount);

    if (!cId || !amt || amt <= 0) {
      return res.status(400).json({ error: "invalid_fields" });
    }

    const rows = await sql`
      SELECT
        g.goalid,
        g.goalstatus,
        a.accountid       AS goalaccountid,
        a.balance         AS goalbalance,
        a.savingaccountid AS savingaccountid
      FROM "Goal" g
      JOIN "Account" a ON a.accountid = g.accountid
      WHERE g.goalid = ${goalId} AND g.childid = ${cId}
      LIMIT 1
    `;

    if (!rows.length) {
      return res.status(404).json({ error: "goal_not_found" });
    }

    const row = rows[0];

    if (row.goalstatus === "Achieved") {
      // Child should redeem instead, not move back to saving
      return res.status(400).json({ error: "goal_completed_no_move_out" });
    }

    const goalAccId = row.goalaccountid;
    const savingAccId = row.savingaccountid;
    const goalBalance = Number(row.goalbalance);

    if (goalBalance < amt) {
      return res
        .status(400)
        .json({ error: "insufficient_goal_balance" });
    }

    // Transfer: Goal → Saving
    await sql`
      UPDATE "Account"
      SET balance = balance - ${amt}
      WHERE accountid = ${goalAccId}
    `;

    const [updSave] = await sql`
      UPDATE "Account"
      SET balance = balance + ${amt}
      WHERE accountid = ${savingAccId}
      RETURNING balance
    `;

    return res.json({
      ok: true,
      newSavingBalance: Number(updSave.balance),
    });
  } catch (err) {
    console.error(err);
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

    if (Number(g[0].balance) > 0) {
      // ⭐ Child must move money out first
      return res.status(400).json({ error: "goal_has_money" });
    }

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

    const cId = Number(childId);
    if (!cId) {
      return res.status(400).json({ error: "invalid_child" });
    }

    const rows = await sql`
      SELECT
        g.goalid,
        g.goalstatus,
        a.accountid AS goalaccountid,
        a.balance   AS goalbalance,
        a.walletid  AS walletid
      FROM "Goal" g
      JOIN "Account" a ON a.accountid = g.accountid
      WHERE g.goalid = ${goalId} AND g.childid = ${cId}
      LIMIT 1
    `;

    if (!rows.length) {
      return res.status(404).json({ error: "goal_not_found" });
    }

    const row = rows[0];

    if (row.goalstatus !== "Achieved") {
      return res.status(400).json({ error: "not_completed" });
    }

    const goalAccId = row.goalaccountid;
    const walletId = row.walletid;
    const goalBalance = Number(row.goalbalance);

    if (goalBalance <= 0) {
      return res.status(400).json({ error: "nothing_to_redeem" });
    }

    // Find SpendingAccount for same wallet
    const spRows = await sql`
      SELECT accountid
      FROM "Account"
      WHERE walletid = ${walletId}
        AND accounttype = 'SpendingAccount'
      LIMIT 1
    `;

    if (!spRows.length) {
      return res.status(500).json({ error: "spending_account_missing" });
    }

    const spendingAccId = spRows[0].accountid;

    // Transfer full balance Goal → Spending
    await sql`
      UPDATE "Account"
      SET balance = balance - ${goalBalance}
      WHERE accountid = ${goalAccId}
    `;

    await sql`
      UPDATE "Account"
      SET balance = balance + ${goalBalance}
      WHERE accountid = ${spendingAccId}
    `;

    // Status remains 'Achieved' (no change)
    return res.json({
      ok: true,
      redeemed: goalBalance,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "redeem_failed" });
  }
}