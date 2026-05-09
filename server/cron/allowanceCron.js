// server/cron/allowanceCron.js
import cron from "node-cron";
import { sql } from "../config/db.js";

export const startAllowanceCron = () => {
  // يعمل كل دقيقة
  cron.schedule("* * * * *", async () => {
    const now = new Date();
    
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const currentDayOfWeek = days[now.getDay()]; 
    const currentDayOfMonth = now.getDate();
    
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const currentTime = `${hours}:${minutes}`;
    const todayStr = now.toISOString().slice(0, 10); // YYYY-MM-DD

    console.log(`💸 Checking Allowances: ${currentDayOfWeek}, Day ${currentDayOfMonth} at ${currentTime}`);

    try {
      // جلب الأطفال الذين حان وقت مصروفهم الآن!
      const rows = await sql`
        SELECT
          a.childid, c.parentid, a.amount, c."default_saving_ratio",
          MAX(CASE WHEN acc.accounttype = 'SavingAccount' THEN acc.accountid END) AS saving_account_id,
          MAX(CASE WHEN acc.accounttype = 'SpendingAccount' THEN acc.accountid END) AS spending_account_id
        FROM "AllowanceSetting" a
        JOIN "Child" c ON c.childid = a.childid
        JOIN "Wallet" w ON w.childid = a.childid
        JOIN "Account" acc ON acc.walletid = w.walletid
        WHERE a.isenabled = true
          AND a.amount > 0
          AND a.time_of_day = ${currentTime}
          AND (
            (a.frequency = 'Weekly' AND a.day_of_week = ${currentDayOfWeek})
            OR 
            (a.frequency = 'Monthly' AND a.day_of_month = ${currentDayOfMonth})
          )
        GROUP BY a.childid, c.parentid, a.amount, c."default_saving_ratio"
      `;

      for (const r of rows) {
        const childId = Number(r.childid);
        const parentId = Number(r.parentid);
        const total = Number(r.amount);
        const saveRatio = Number(r.default_saving_ratio ?? 0);
        
        // منع التكرار في نفس اليوم
        const already = await sql`SELECT 1 FROM "AllowanceRun" WHERE childid = ${childId} AND run_date = ${todayStr}::date LIMIT 1`;
        if (already.length > 0) continue;

        // التحقق من رصيد الأب
        const parentAcc = await sql`
          SELECT acc.accountid, acc.balance
          FROM "Wallet" w
          JOIN "Account" acc ON acc.walletid = w.walletid
          WHERE w.parentid = ${parentId} AND acc.accounttype = 'ParentAccount' LIMIT 1
        `;

        if (parentAcc.length === 0) continue;
        
        const parentAccountId = Number(parentAcc[0].accountid);
        const parentBalance = Number(parentAcc[0].balance);

        if (parentBalance < total) {
          console.warn(`⚠️ فشل التحويل: رصيد الأب ${parentId} لا يغطي مصروف الطفل ${childId}. المطلوب: ${total}, المتوفر: ${parentBalance}`);
          // هنا يمكنك إضافة كود لإرسال إشعار (Notification) للأب بأن رصيده غير كافٍ للمصروف!
          continue; 
        }

        const saveAmount = +(total * saveRatio).toFixed(2);
        const spendAmount = +(total - saveAmount).toFixed(2);

        // تنفيذ المعاملة المالية (Transaction)
        await sql`BEGIN`;
        try {
          await sql`UPDATE "Account" SET balance = balance - ${total} WHERE accountid = ${parentAccountId}`;
          await sql`UPDATE "Account" SET balance = balance + ${saveAmount} WHERE accountid = ${r.saving_account_id}`;
          await sql`UPDATE "Account" SET balance = balance + ${spendAmount} WHERE accountid = ${r.spending_account_id}`;

          await sql`
            INSERT INTO "Transaction"
              ("transactiontype","amount","transactiondate","transactionstatus","merchantname","sourcetype","transactioncategory","senderAccountId","receiverAccountId")
            VALUES
              ('Transfer', ${saveAmount}, CURRENT_TIMESTAMP, 'Completed', 'المصروف التلقائي (توفير)', 'SYSTEM', 'Allowance', ${parentAccountId}, ${r.saving_account_id}),
              ('Transfer', ${spendAmount}, CURRENT_TIMESTAMP, 'Completed', 'المصروف التلقائي (مصروف)', 'SYSTEM', 'Allowance', ${parentAccountId}, ${r.spending_account_id})
          `;

          await sql`INSERT INTO "AllowanceRun" (childid, run_date) VALUES (${childId}, ${todayStr}::date)`;
          await sql`COMMIT`;
          console.log(`✅ تم تحويل المصروف للطفل ${childId} بنجاح!`);
        } catch (e) {
          await sql`ROLLBACK`;
          console.error(`❌ فشل في تنفيذ التحويل للطفل ${childId}:`, e);
        }
      }
    } catch (err) {
      console.error("Allowance cron failed:", err);
    }
  }, { timezone: "Asia/Riyadh" });
};