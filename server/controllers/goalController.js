import { sql } from '../config/db.js';

// Ensure the child has a wallet and return walletid
async function ensureWallet(childId, s) {
  const w = await s`
    SELECT "walletid" FROM "Wallet"
    WHERE "childid" = ${childId}
    LIMIT 1
  `;
  if (w.length) return w[0].walletid;

  const ins = await s`
    INSERT INTO "Wallet"("parentid","childid","walletstatus")
    VALUES (NULL, ${childId}, 'Active')
    RETURNING "walletid"
  `;
  return ins[0].walletid;
}

// Ensure SavingAccount and SpendingAccount exist for a wallet
async function ensureCoreAccounts(walletId, s) {
  await s`
    INSERT INTO "Account"("walletid","savingaccountid","accounttype","currency","balance","limitamount")
    SELECT ${walletId}, NULL, 'SavingAccount', 'SAR', 0, 0
    WHERE NOT EXISTS (
      SELECT 1 FROM "Account"
      WHERE "walletid" = ${walletId} AND "accounttype" = 'SavingAccount'
    )
  `;

  await s`
    INSERT INTO "Account"("walletid","savingaccountid","accounttype","currency","balance","limitamount")
    SELECT ${walletId}, NULL, 'SpendingAccount', 'SAR', 0, 0
    WHERE NOT EXISTS (
      SELECT 1 FROM "Account"
      WHERE "walletid" = ${walletId} AND "accounttype" = 'SpendingAccount'
    )
  `;
}

/* ---------- Routes ---------- */

/** POST /api/children/:childId/wallet/setup */
export async function setupChildWallet(req, res) {
  try {
    const childId = Number(req.params.childId);

    const walletId = await ensureWallet(childId, sql);
    await ensureCoreAccounts(walletId, sql);

    res.status(201).json({ walletId });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'wallet_setup_failed' });
  }
}

/** GET /api/children/:childId/save-balance */
export async function getSaveBalance(req, res) {
  try {
    const childId = Number(req.params.childId);

    const w = await sql`
      SELECT "walletid" FROM "Wallet"
      WHERE "childid" = ${childId}
      LIMIT 1
    `;
    if (!w.length) return res.json({ balance: 0 });

    const walletId = w[0].walletid;

    const s = await sql`
      SELECT "balance" FROM "Account"
      WHERE "walletid" = ${walletId} AND "accounttype" = 'SavingAccount'
      LIMIT 1
    `;
    const balance = s.length ? Number(s[0].balance) : 0;
    res.json({ balance });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'get_save_balance_failed' });
  }
}

/** GET /api/children/:childId/goals */
export async function listChildGoals(req, res) {
  try {
    const childId = Number(req.params.childId);
    const rows = await sql`
      SELECT
        g."goalid",
        g."goalname",
        g."targetamount",
        g."goalstatus",
        a."balance" AS balance
      FROM "Goal" g
      JOIN "Account" a ON a."accountid" = g."accountid"
      WHERE g."childid" = ${childId}
      ORDER BY g."goalid" DESC
    `;
    res.json(rows);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'list_goals_failed' });
  }
}

/** POST /api/goals   body: { childId, goalName, targetAmount } */
export async function createGoal(req, res) {
  try {
    const { childId, goalName, targetAmount } = req.body;

    if (!childId || !goalName || targetAmount == null) {
      return res.status(400).json({ error: 'missing_fields' });
    }

    const cId = Number(childId);
    const tAmount = Number(targetAmount);

    // 1) Ensure wallet + saving/spending exist
    const walletId = await ensureWallet(cId, sql);
    await ensureCoreAccounts(walletId, sql);

    // 2) Get SavingAccount id
    const sav = await sql`
      SELECT "accountid" FROM "Account"
      WHERE "walletid" = ${walletId} AND "accounttype" = 'SavingAccount'
      LIMIT 1
    `;
    if (!sav.length) {
      return res.status(500).json({ error: 'saving_account_missing' });
    }
    const savingAccountId = sav[0].accountid;

    // 3) Create GoalAccount linked to SavingAccount (limitamount = target)
    const gacc = await sql`
      INSERT INTO "Account"("walletid","savingaccountid","accounttype","currency","balance","limitamount")
      VALUES (${walletId}, ${savingAccountId}, 'GoalAccount', 'SAR', 0, ${tAmount})
      RETURNING "accountid","balance"
    `;
    const goalAccountId = gacc[0].accountid;

    // 4) Insert Goal (بدون goaldescription)
    const g = await sql`
      INSERT INTO "Goal"("childid","accountid","goalname","targetamount","goalstatus")
      VALUES (${cId}, ${goalAccountId}, ${goalName}, ${tAmount}, 'InProgress')
      RETURNING *
    `;

    res.status(201).json({ goal: g[0] });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'create_goal_failed' });
  }
}

/** POST /api/goals/:goalId/contributions   body: { childId, amount } */
export async function contributeToGoal(req, res) {
  try {
    const goalId = Number(req.params.goalId);
    const { childId, amount } = req.body;

    if (!childId || !amount) {
      return res.status(400).json({ error: 'missing_fields' });
    }

    const cId = Number(childId);
    const amt = Number(amount);

    // 1) Fetch goal + related accounts
    const g = await sql`
      SELECT
        g."goalid",
        g."targetamount",
        ga."accountid"       AS goalaccountid,
        ga."savingaccountid" AS savingaccountid
      FROM "Goal" g
      JOIN "Account" ga ON ga."accountid" = g."accountid"
      WHERE g."goalid" = ${goalId} AND g."childid" = ${cId}
      LIMIT 1
    `;

    if (!g.length) {
      return res.status(404).json({ error: 'goal_not_found' });
    }

    const goalAccountId   = g[0].goalaccountid;
    const savingAccountId = g[0].savingaccountid;
    const targetAmount    = Number(g[0].targetamount);

    // 2) Check saving balance
    const sBal = await sql`
      SELECT "balance" FROM "Account" WHERE "accountid" = ${savingAccountId}
    `;
    const savingBal = Number(sBal[0]?.balance ?? 0);
    if (savingBal < amt) {
      return res.status(400).json({ error: 'insufficient_balance' });
    }

    // 3) Insert transaction record
    await sql`
      INSERT INTO "Transaction"(
        "transactiontype","amount","transactiondate","transactionstatus",
        "merchantname","sourcetype","transactioncategory",
        "senderAccountId","receiverAccountId"
      )
      VALUES (
        'Transfer', ${amt}, CURRENT_TIMESTAMP, 'Completed',
        'Goal Contribution', 'Transfer', 'internal',
        ${savingAccountId}, ${goalAccountId}
      )
    `;

    // 4) Update balances
    await sql`
      UPDATE "Account" SET "balance" = "balance" - ${amt}
      WHERE "accountid" = ${savingAccountId}
    `;

    const updGoal = await sql`
      UPDATE "Account" SET "balance" = "balance" + ${amt}
      WHERE "accountid" = ${goalAccountId}
      RETURNING "balance"
    `;

    const newGoalBalance = Number(updGoal[0].balance);

    // 5) If achieved, mark goal Achieved
    if (newGoalBalance >= targetAmount) {
      await sql`
        UPDATE "Goal" SET "goalstatus" = 'Achieved'
        WHERE "goalid" = ${goalId}
      `;
    }

    res.status(201).json({
      ok: true,
      goalId,
      goalBalance: newGoalBalance,
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'contribution_failed' });
  }
}
