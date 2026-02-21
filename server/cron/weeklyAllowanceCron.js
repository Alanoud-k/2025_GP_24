// server/cron/weeklyAllowanceCron.js
import cron from "node-cron";
import { sql } from "../config/db.js";

export const startWeeklyAllowanceCron = () => {
  cron.schedule(
    "0 0 * * 0", // Sunday 00:00
    //cron.schedule("* * * * *",
    async () => {
      console.log("Running weekly allowance job...");

      const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD

      try {
        // 1) كل الأطفال اللي allowance مفعّل لهم + parentId + حسابات الطفل
        const rows = await sql`
          SELECT
            a.childid,
            c.parentid,
            a.amount,
            c."default_saving_ratio",
            MAX(CASE WHEN acc.accounttype = 'SavingAccount' THEN acc.accountid END)   AS saving_account_id,
            MAX(CASE WHEN acc.accounttype = 'SpendingAccount' THEN acc.accountid END) AS spending_account_id
          FROM "AllowanceSetting" a
          JOIN "Child" c ON c.childid = a.childid
          JOIN "Wallet" w ON w.childid = a.childid
          JOIN "Account" acc ON acc.walletid = w.walletid
          WHERE a.isenabled = true
            AND a.amount > 0
          GROUP BY a.childid, c.parentid, a.amount, c."default_saving_ratio"        `;

        let applied = 0;
        let skippedInsufficient = 0;

        for (const r of rows) {
          const childId = Number(r.childid);
          const parentId = Number(r.parentid);
          const total = Number(r.amount);
          const saveRatio = Number(r.default_saving_ratio ?? 0);
          const savingAccountId = r.saving_account_id;
          const spendingAccountId = r.spending_account_id;

          if (!savingAccountId || !spendingAccountId) {
            console.warn(`Skip child ${childId}: missing saving/spending accounts`);
            continue;
          }

          // 2) منع التكرار بنفس اليوم
          const already = await sql`
            SELECT 1
            FROM "AllowanceRun"
            WHERE childid = ${childId} AND run_date = ${today}::date
            LIMIT 1
          `;
          if (already.length > 0) continue;

          // 3) نجيب ParentAccount حق الأب
          // نفترض أن Wallet الأب موجود وفيه parentid = parentId
          const parentAcc = await sql`
            SELECT acc.accountid, acc.balance
            FROM "Wallet" w
            JOIN "Account" acc ON acc.walletid = w.walletid
            WHERE w.parentid = ${parentId}
              AND acc.accounttype = 'ParentAccount'
            LIMIT 1
          `;

          if (parentAcc.length === 0) {
            console.warn(`Skip child ${childId}: parent ${parentId} has no ParentAccount`);
            continue;
          }

          const parentAccountId = Number(parentAcc[0].accountid);
          const parentBalance = Number(parentAcc[0].balance);

          // 4) تأكد الرصيد يكفي
          if (parentBalance < total) {
            console.warn(`Skip child ${childId}: insufficient parent balance (${parentBalance} < ${total})`);
            skippedInsufficient++;
            continue;
          }

const saveAmount = +(total * saveRatio).toFixed(2);
const spendAmount = +(total - saveAmount).toFixed(2);

          // 5) (اختياري لكن مهم) نفّذيها كـ transaction DB عشان ما يصير نص تحديث
          await sql`BEGIN`;

          try {
            // خصم من الأب
            await sql`
              UPDATE "Account"
              SET balance = balance - ${total}
              WHERE accountid = ${parentAccountId}
            `;

            // إضافة للطفل
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

            // Transactions: Transfer (من الأب -> حسابات الطفل)
            await sql`
              INSERT INTO "Transaction"
                ("transactiontype","amount","transactiondate","transactionstatus","merchantname","sourcetype",
                 "transactioncategory","senderAccountId","receiverAccountId")
              VALUES
                ('Transfer', ${saveAmount}, CURRENT_TIMESTAMP, 'Completed', 'Weekly Allowance', 'SYSTEM',
                 'Allowance', ${parentAccountId}, ${savingAccountId}),
                ('Transfer', ${spendAmount}, CURRENT_TIMESTAMP, 'Completed', 'Weekly Allowance', 'SYSTEM',
                 'Allowance', ${parentAccountId}, ${spendingAccountId})
            `;

            // تسجيل run لليوم
            await sql`
              INSERT INTO "AllowanceRun" (childid, run_date)
              VALUES (${childId}, ${today}::date)
            `;

            await sql`COMMIT`;
            applied++;
          } catch (e) {
            await sql`ROLLBACK`;
            throw e;
          }
        }

        console.log(`Weekly allowance applied to ${applied} children`);
        if (skippedInsufficient) {
          console.log(`Skipped (insufficient parent balance): ${skippedInsufficient}`);
        }
      } catch (err) {
        console.error("Weekly allowance cron failed:", err);
      }
    },
    {
      timezone: "Asia/Riyadh",
    }
  );
};
