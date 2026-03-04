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
        // 1. جلب حساب الصرف للطفل
        const spendingAccounts = await sql`
            SELECT a."accountid"
            FROM "Account" a
            JOIN "Wallet" w ON a."walletid" = w."walletid"
            WHERE w."childid" = ${childId}
            AND a."accounttype" = 'SpendingAccount'
        `;

        if (spendingAccounts.length === 0) return {};

        const spendingAccountId = spendingAccounts[0].accountid;

        // 2. تجميع المصروفات بناءً على الفئة (Category)
        const categoriesData = await sql`
            SELECT "category", SUM("amount") AS total
            FROM "Transaction"
            WHERE "senderAccountId" = ${spendingAccountId}
            AND "transactiontype" = 'Expense' -- تأكدي من اسم نوع العملية في قاعدتكم
            GROUP BY "category"
        `;

        // 3. تحويل النتيجة إلى Object يسهل على Flutter قراءته
        const result = {};
        categoriesData.forEach(row => {
            if(row.category) {
                result[row.category] = Number(row.total);
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
            SELECT c."firstName" AS name, SUM(t."amount") AS total
            FROM "Transaction" t
            JOIN "Account" a ON t."senderAccountId" = a."accountid"
            JOIN "Wallet" w ON a."walletid" = w."walletid"
            JOIN "Child" c ON w."childid" = c."id"
            WHERE c."parentId" = ${parentId}
            AND t."transactiontype" = 'Expense'
            GROUP BY c."firstName"
        `;

        const result = {};
        childrenSpending.forEach(row => {
            result[row.name] = Number(row.total ?? 0);
        });

        return result;
    } catch (error) {
        console.error("Parent Chart Service Error:", error);
        throw error;
    }
}