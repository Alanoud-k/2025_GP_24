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

        const insights = [];

        // --------------------------------------------------
        // 1️⃣ Weekly spending
        // --------------------------------------------------

        const weeklySpending = await sql`
            SELECT SUM("amount") AS total
            FROM "Transaction"
            WHERE "senderAccountId" = ${spendingAccountId}
            AND "transactiondate" >= date_trunc('week', CURRENT_DATE)
            AND "transactiontype"::text = 'Payment'
        `;

        const totalSpending = Number(weeklySpending[0].total ?? 0);

        if (totalSpending > 0) {
    insights.push({
        type: "weekly",
        message: `You spent ${totalSpending.toFixed(2)} SAR this week.`
    });
} else {
    insights.push({
        type: "weekly-none",
        message: "You haven't spent anything yet this week."
    });
}

        // --------------------------------------------------
        // 2️⃣ Category percentage
        // --------------------------------------------------

        const categories = await sql`
            SELECT "transactioncategory", SUM("amount") AS total
            FROM "Transaction"
            WHERE "senderAccountId" = ${spendingAccountId}
            AND "transactiondate" >= date_trunc('week', CURRENT_DATE)
            AND "transactiontype"::text = 'Payment'
            GROUP BY "transactioncategory"
        `;

        let maxCategory = null;
        let maxAmount = 0;

        categories.forEach(row => {
            const amount = Number(row.total ?? 0);
            if (amount > maxAmount) {
                maxAmount = amount;
                maxCategory = row.transactioncategory;
            }
        });

        if (maxCategory && totalSpending > 0) {
            const percentage = Math.round((maxAmount / totalSpending) * 100);

            insights.push({
                type: "category",
                message: `You spent ${percentage}% of your money on ${maxCategory} this week.`
            });
        }

        // --------------------------------------------------
        // 3️⃣ Self control (no spending yesterday)
        // --------------------------------------------------

        const yesterday = await sql`
            SELECT COUNT(*) AS count
            FROM "Transaction"
            WHERE "senderAccountId" = ${spendingAccountId}
            AND DATE("transactiondate") = CURRENT_DATE - INTERVAL '1 day'
            AND "transactiontype"::text = 'Payment'
        `;

        const yesterdayCount = Number(yesterday[0].count ?? 0);

        if (yesterdayCount === 0) {
            insights.push({
                type: "self-control",
                message: "You didn’t spend anything yesterday, nice self-control!"
            });
        }

        // --------------------------------------------------
        // 5️⃣ Goal progress insight
        // --------------------------------------------------

const goal = await sql`
SELECT 
    g.goalname,
    g.targetamount,
    a.balance
FROM "Goal" g
JOIN "Account" a ON g.accountid = a.accountid
WHERE g.childid = ${childId}
AND g.goalstatus = 'InProgress'
ORDER BY g.goalid DESC
LIMIT 1
`;

if (goal.length > 0) {

    const goalName = goal[0].goalname;
    const target = Number(goal[0].targetamount ?? 0);
    const saved = Number(goal[0].balance ?? 0);

    if (target > 0) {

        const progress = Math.round((saved / target) * 100);

        if (progress === 0) {

            insights.push({
                type: "goal-start",
                message: `Start saving to reach your ${goalName} goal!`
            });

        } else if (progress >= 80 && progress < 100) {

            const remaining = target - saved;

            insights.push({
                type: "goal-close",
                message: `Only ${remaining.toFixed(0)} SAR left to reach your ${goalName}!`
            });

        } else if (progress > 0 && progress < 80) {

            insights.push({
                type: "goal-progress",
                message: `Great progress! You're ${progress}% closer to your ${goalName} goal.`
            });

        }

    }
}
        // --------------------------------------------------
        // 4️⃣ Category change vs last week
        // --------------------------------------------------

        const thisWeek = await sql`
            SELECT "transactioncategory", SUM("amount") AS total
            FROM "Transaction"
            WHERE "senderAccountId" = ${spendingAccountId}
            AND "transactiondate" >= date_trunc('week', CURRENT_DATE)
            AND "transactiontype"::text = 'Payment'
            GROUP BY "transactioncategory"
        `;

        const lastWeek = await sql`
            SELECT "transactioncategory", SUM("amount") AS total
            FROM "Transaction"
            WHERE "senderAccountId" = ${spendingAccountId}
            AND "transactiondate" >= date_trunc('week', CURRENT_DATE) - INTERVAL '1 week'
            AND "transactiondate" < date_trunc('week', CURRENT_DATE)
            AND "transactiontype"::text = 'Payment'
            GROUP BY "transactioncategory"
        `;

        

        const lastWeekMap = {};
        lastWeek.forEach(row => {
            lastWeekMap[row.transactioncategory] = Number(row.total ?? 0);
        });

        thisWeek.forEach(row => {
            const current = Number(row.total ?? 0);
            const previous = lastWeekMap[row.transactioncategory] ?? 0;

            if (previous > 0) {
                const change = ((current - previous) / previous) * 100;

                if (change > 20) {
                    insights.push({
                        type: "increase",
                        message: `${row.transactioncategory} spending increased by ${Math.round(change)}% this week.`
                    });
                }
            }
        });

        return insights;

    } catch (error) {
        console.error("Insight Service Error:", error);
        throw error;
    }
}


export async function getGoalInsights(childId) {

    const goals = await sql`
        SELECT 
            g.goalname,
            g.targetamount,
            a.balance
        FROM "Goal" g
        JOIN "Account" a ON g.accountid = a.accountid
        WHERE g.childid = ${childId}
        AND g.goalstatus = 'InProgress'
        ORDER BY g.goalid DESC
        LIMIT 3
    `;

    const insights = [];

    goals.forEach(goal => {

        const goalName = goal.goalname;
        const target = Number(goal.targetamount ?? 0);
        const saved = Number(goal.balance ?? 0);

        if (target <= 0) return;

        const progress = Math.round((saved / target) * 100);

        if (progress === 0) {
            insights.push({
                type: "goal-start",
                message: `Start saving for your ${goalName}!`
            });

        } else if (progress >= 80 && progress < 100) {

            const remaining = target - saved;

            insights.push({
                type: "goal-close",
                message: `Only ${remaining.toFixed(0)} SAR left to reach your ${goalName}!`
            });

        } else {
            insights.push({
                type: "goal-progress",
                message: `You're ${progress}% closer to your ${goalName}!`
            });
        }

    });

    return insights;
}

// دالة الطفل المحدثة
export async function getChildChartData(childId, month, year) {
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

        // التعديل هنا: فلترة العمليات بالشهر والسنة المطلوبة
        const categoriesData = await sql`
            SELECT "transactioncategory", SUM("amount") AS total
            FROM "Transaction"
            WHERE "senderAccountId" = ${spendingAccountId}
            AND "transactiontype"::text = 'Payment'
            AND EXTRACT(MONTH FROM "transactiondate") = ${month}
            AND EXTRACT(YEAR FROM "transactiondate") = ${year}
            GROUP BY "transactioncategory"
        `;

        const result = {};
        categoriesData.forEach(row => {
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

// دالة الأب المحدثة
export async function getParentChartData(parentId, month, year, childName) {
    try {
        // إذا تم تحديد طفل معين، نجلب تفاصيل تصنيفات مصروفاته
        if (childName && childName !== "All") {
            const categoriesData = await sql`
                SELECT t."transactioncategory" AS name, SUM(t."amount") AS total
                FROM "Transaction" t
                JOIN "Account" a ON t."senderAccountId" = a.accountid
                JOIN "Wallet" w ON a.walletid = w.walletid
                JOIN "Child" c ON w.childid = c.childid
                WHERE c.parentid = ${parentId}
                AND c.firstname = ${childName}
                AND t.transactiontype::text = 'Payment'
                AND EXTRACT(MONTH FROM t.transactiondate) = ${month}
                AND EXTRACT(YEAR FROM t.transactiondate) = ${year}
                GROUP BY t."transactioncategory"
            `;

            const result = {};
            categoriesData.forEach(row => {
                if(row.name && row.name !== "Uncategorized") {
                    result[row.name] = Number(row.total ?? 0);
                }
            });
            return result;
        } 
        // أما إذا كان الخيار "All"، نجلب إجمالي صرف كل طفل للمقارنة بينهم
        else {
            const childrenSpending = await sql`
                SELECT c.firstname AS name, SUM(t.amount) AS total
                FROM "Transaction" t
                JOIN "Account" a ON t."senderAccountId" = a.accountid
                JOIN "Wallet" w ON a.walletid = w.walletid
                JOIN "Child" c ON w.childid = c.childid
                WHERE c.parentid = ${parentId}
                AND t.transactiontype::text = 'Payment'
                AND EXTRACT(MONTH FROM t.transactiondate) = ${month}
                AND EXTRACT(YEAR FROM t.transactiondate) = ${year}
                GROUP BY c.firstname
            `;

            const result = {};
            childrenSpending.forEach(row => {
                const cName = row.name || "Child"; 
                result[cName] = Number(row.total ?? 0);
            });
            return result;
        }
    } catch (error) {
        console.error("Parent Chart Service Error:", error);
        throw error;
    }
}