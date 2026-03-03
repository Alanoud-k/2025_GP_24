const pool = require('../config/db'); // adjust if your DB connection file is different

async function getChildInsights(childId) {
    try {

        // 1️⃣ Get child spending account
        const spendingAccountQuery = `
            SELECT a.accountid
            FROM Account a
            JOIN Wallet w ON a.walletid = w.walletid
            WHERE w.childid = $1
            AND a.accounttype = 'Spending'
        `;

        const spendingResult = await pool.query(spendingAccountQuery, [childId]);

        if (spendingResult.rows.length === 0) {
            return [];
        }

        const spendingAccountId = spendingResult.rows[0].accountid;

        // 2️⃣ Get this week total spending
        const weeklySpendingQuery = `
            SELECT SUM(amount) AS total
            FROM Transaction
            WHERE senderAccountId = $1
            AND transactiondate >= date_trunc('week', CURRENT_DATE)
            AND transactiontype = 'Payment'
        `;

        const weeklyResult = await pool.query(weeklySpendingQuery, [spendingAccountId]);
        const totalSpending = weeklyResult.rows[0].total || 0;

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

module.exports = {
    getChildInsights
};