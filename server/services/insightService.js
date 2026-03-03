// services/insightService.js

import { sql } from '../config/db.js';

export async function getChildInsights(childId) {
    try {

        const spendingAccounts = await sql`
            SELECT a.accountid
            FROM Account a
            JOIN Wallet w ON a.walletid = w.walletid
            WHERE w.childid = ${childId}
            AND a.accounttype = 'Spending'
        `;

        if (spendingAccounts.length === 0) {
            return [];
        }

        const spendingAccountId = spendingAccounts[0].accountid;

        const weeklySpending = await sql`
            SELECT SUM(amount) AS total
            FROM Transaction
            WHERE senderAccountId = ${spendingAccountId}
            AND transactiondate >= date_trunc('week', CURRENT_DATE)
            AND transactiontype = 'Payment'
        `;

        const totalSpending = weeklySpending[0].total || 0;

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