// server/cron/weeklyAllowanceCron.js
import cron from "node-cron";
import { sql } from "../config/db.js";

export const startWeeklyAllowanceCron = () => {
  cron.schedule("0 0 * * 0", async () => {
    console.log("Running weekly allowance job...");

    const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD

    try {
      // نجيب كل الأطفال اللي allowance مفعّل لهم + حساباتهم
      const rows = await sql`
        SELECT
          a.childid,
          a.amount,
          a.savepercentage,
          MAX(CASE WHEN acc.accounttype = 'SavingAccount' THEN acc.accountid END)   AS saving_account_id,
          MAX(CASE WHEN acc.accounttype = 'SpendingAccount' THEN acc.accountid END) AS spending_account_id
        FROM "AllowanceSetting" a
        JOIN "Wallet" w ON w.childid = a.childid
        JOIN "Account" acc ON acc.walletid = w.walletid
        WHERE a.isenabled = true
          AND a.amount > 0
        GROUP BY a.childid, a.amount, a.savepercentage
      `;

      let applied = 0;

      for (const r of rows) {
        const childId = Number(r.childid);
        const total = Number(r.amount);
        const savePct = Number(r.savepercentage);

        const savingAccountId = r.saving_account_id;
        const spendingAccountId = r.spending_account_id;

        if (!savingAccountId || !spendingAccountId) {
          console.warn(`Skip child ${childId}: missing saving/spending accounts`);
          continue;
        }

        // منع التكرار بنفس اليوم
        const already = await sql`
          SELECT 1
          FROM "AllowanceRun"
          WHERE childid = ${childId} AND run_date = ${today}::date
          LIMIT 1
        `;
        if (already.length > 0) continue;

        const saveAmount = +(total * (savePct / 100)).toFixed(2);
        const spendAmount = +(total - saveAmount).toFixed(2);

        // تحديث الأرصدة
        await sql`
          UPDATE "Account"
          SET balance = balance + ${saveAmount}
          WHERE accountid = ${savingAccountId}
        `;
        await sql`
          UPDATE "Account"
          SET balance = balance + ${spendAmount}
          WHERE accountid = ${spendingAccountId}
        `;

        // تسجيل Transactions (receiverAccountId إجباري عندكم)
        await sql`
          INSERT INTO "Transaction"
            ("transactiontype","amount","transactiondate","transactionstatus","merchantname","sourcetype",
             "transactioncategory","senderAccountId","receiverAccountId")
          VALUES
            ('Deposit', ${saveAmount}, CURRENT_TIMESTAMP, 'SUCCESS', 'Weekly Allowance', 'SYSTEM',
             'Allowance', NULL, ${savingAccountId}),
            ('Deposit', ${spendAmount}, CURRENT_TIMESTAMP, 'SUCCESS', 'Weekly Allowance', 'SYSTEM',
             'Allowance', NULL, ${spendingAccountId})
        `;

        // نسجل run لليوم
        await sql`
          INSERT INTO "AllowanceRun" (childid, run_date)
          VALUES (${childId}, ${today}::date)
        `;

        applied++;
      }

      console.log(`Weekly allowance applied to ${applied} children`);
    } catch (err) {
      console.error("Weekly allowance cron failed:", err);
    }
  },
  {
    timezone: "Asia/Riyadh", 
  }
);
};
