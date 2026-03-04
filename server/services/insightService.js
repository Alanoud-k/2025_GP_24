import { sql } from '../config/db.js';

export async function getChildInsights(childId) {
    try {

        const spendingAccounts = await sql`
            SELECT a."accountid"
            FROM "Account" a
            JOIN "Wallet" w ON a."walletid" = w."walletid"
            WHERE w."childid" = ${childId}
            AND a."accounttype" = 'SpendingAccount'
        `;

        if (spendingAccounts.length === 0) return [];

        const spendingAccountId = spendingAccounts[0].accountid;

        const weeklySpending = await sql`
            SELECT SUM("amount") AS total
            FROM "Transaction"
            WHERE "senderAccountId" = ${spendingAccountId}
            AND "transactiondate" >= date_trunc('week', CURRENT_DATE)
            AND "transactiontype" = 'Transfer'
        `;

        const totalSpending = Number(weeklySpending[0].total ?? 0);

        const insights = [];

        if (totalSpending > 0) {
            insights.push({
                type: "info",
                message: `You spent ${totalSpending} SAR this week.`
            });
        }

        return insights;

    } catch (error) {
        console.error("Insight Service Error:", error);
        throw error;
    }
}


export async function getChildChartData(childId) {
    try {
        const spendingAccounts = await sql`
            SELECT a."accountid"
            FROM "Account" a
            JOIN "Wallet" w ON a."walletid" = w."walletid"
            WHERE w."childid" = ${childId}
            AND a."accounttype" = 'SpendingAccount'
        `;

        if (spendingAccounts.length === 0) return {};

        const spendingAccountId = spendingAccounts[0].accountid;

      // التعديل هنا: استخدمنا ::text لتخطي صرامة الـ ENUM وبحثنا عن Payment
        const categoriesData = await sql`
            SELECT "transactioncategory", SUM("amount") AS total
            FROM "Transaction"
            WHERE "senderAccountId" = ${spendingAccountId}
            AND "transactiontype"::text = 'Payment'
            GROUP BY "transactioncategory"
        `;

        const result = {};
        categoriesData.forEach(row => {
            // تجاهل العمليات غير المصنفة حتى لا تكسر الرسم البياني
            if(row.transactioncategory && row.transactioncategory !== "Uncategorized") {
                result[row.transactioncategory] = Number(row.total);
            }
        });

        return result;
    } catch (error) {
        console.error("Child Chart Service Error:", error);
        throw error;
    }
}


export async function getParentChartData(parentId) {
    try {
        const childrenSpending = await sql`
            SELECT c.firstname AS name, SUM(t.amount) AS total
            FROM "Transaction" t
            JOIN "Account" a ON t."senderAccountId" = a.accountid
            JOIN "Wallet" w ON a.walletid = w.walletid
            JOIN "Child" c ON w.childid = c.childid
            WHERE w.parentid = ${parentId}
            AND t.transactiontype::text = 'Payment'
            GROUP BY c.firstname
        `;

        const result = {};
        childrenSpending.forEach(row => {
            // في حال كان الاسم فارغاً لسبب ما، نعرض كلمة Child كبديل آمن
            const childName = row.name || "Child"; 
            result[childName] = Number(row.total ?? 0);
        });

        return result;
    } catch (error) {
        console.error("Parent Chart Service Error:", error);
        throw error;
    }
}