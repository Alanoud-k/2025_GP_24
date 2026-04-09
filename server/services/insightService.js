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
export async function getChildChartData(childId, month, year, period = 'month') {
    try {
        const spendingAccounts = await sql`
            SELECT a."accountid" FROM "Account" a JOIN "Wallet" w ON a."walletid" = w."walletid"
            WHERE w."childid" = ${childId} AND a."accounttype" = 'SpendingAccount'
        `;
        if (spendingAccounts.length === 0) return {};
        const spendingAccountId = spendingAccounts[0].accountid;

        const categoriesData = await sql`
            SELECT "transactioncategory", SUM("amount") AS total
            FROM "Transaction"
            WHERE "senderAccountId" = ${spendingAccountId}
            AND "transactiontype"::text = 'Payment'
            AND (
                (${period} = 'week' AND "transactiondate" >= date_trunc('week', CURRENT_DATE)) OR
                (${period} = 'month' AND EXTRACT(MONTH FROM "transactiondate") = ${month} AND EXTRACT(YEAR FROM "transactiondate") = ${year}) OR
                (${period} = 'year' AND EXTRACT(YEAR FROM "transactiondate") = ${year})
            )
            GROUP BY "transactioncategory"
        `;

        const result = {};
        categoriesData.forEach(row => {
            if(row.transactioncategory && row.transactioncategory !== "Uncategorized") result[row.transactioncategory] = Number(row.total);
        });
        return result;
    } catch (error) { console.error("Child Chart Error:", error); throw error; }
}

// دالة الأب المحدثة
export async function getParentChartData(parentId, month, year, childName, period = 'month') {
    try {
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
                AND (
                    (${period} = 'week' AND t.transactiondate >= date_trunc('week', CURRENT_DATE)) OR
                    (${period} = 'month' AND EXTRACT(MONTH FROM t.transactiondate) = ${month} AND EXTRACT(YEAR FROM t.transactiondate) = ${year}) OR
                    (${period} = 'year' AND EXTRACT(YEAR FROM t.transactiondate) = ${year})
                )
                GROUP BY t."transactioncategory"
            `;
            const result = {};
            categoriesData.forEach(row => {
                if(row.name && row.name !== "Uncategorized") result[row.name] = Number(row.total ?? 0);
            });
            return result;
        } else {
            const childrenSpending = await sql`
                SELECT c.firstname AS name, SUM(t.amount) AS total
                FROM "Transaction" t
                JOIN "Account" a ON t."senderAccountId" = a.accountid
                JOIN "Wallet" w ON a.walletid = w.walletid
                JOIN "Child" c ON w.childid = c.childid
                WHERE c.parentid = ${parentId}
                AND t.transactiontype::text = 'Payment'
                AND (
                    (${period} = 'week' AND t.transactiondate >= date_trunc('week', CURRENT_DATE)) OR
                    (${period} = 'month' AND EXTRACT(MONTH FROM t.transactiondate) = ${month} AND EXTRACT(YEAR FROM t.transactiondate) = ${year}) OR
                    (${period} = 'year' AND EXTRACT(YEAR FROM t.transactiondate) = ${year})
                )
                GROUP BY c.firstname
            `;
            const result = {};
            childrenSpending.forEach(row => {
                const cName = row.name || "Child"; 
                result[cName] = Number(row.total ?? 0);
            });
            return result;
        }
    } catch (error) { console.error("Parent Chart Error:", error); throw error; }
}

export async function getParentInsights(parentId) {
    try {
        const insights = [];

        // ----------------------------------------
        // Get children
        // ----------------------------------------
        const children = await sql`
            SELECT c.childid, c.firstname
            FROM "Child" c
            WHERE c.parentid = ${parentId}
        `;

        // ----------------------------------------
        // 🟥 NO CHILDREN
        // ----------------------------------------
        if (children.length === 0) {
            return [
                { message: "You haven’t added any children yet" },
                { message: "Add a child to start tracking spending" },
                { message: "Insights will appear once activity begins" },
            ];
        }

        const childIds = children.map(c => c.childid);

        // ----------------------------------------
        // Get all spending accounts
        // ----------------------------------------
        const accounts = await sql`
            SELECT a.accountid, w.childid
            FROM "Account" a
            JOIN "Wallet" w ON a.walletid = w.walletid
            WHERE w.childid = ANY(${childIds})
            AND a.accounttype = 'SpendingAccount'
        `;

        if (accounts.length === 0) {
            return [{ message: "No spending data available yet" }];
        }

        const accountIds = accounts.map(a => a.accountid);

        // ----------------------------------------
        // WEEKLY TOTAL
        // ----------------------------------------
        const weekly = await sql`
            SELECT 
                w.childid,
                SUM(t.amount) as total
            FROM "Transaction" t
            JOIN "Account" a ON t."senderAccountId" = a.accountid
            JOIN "Wallet" w ON a.walletid = w.walletid
            WHERE a.accountid = ANY(${accountIds})
            AND t.transactiontype = 'Payment'
            AND t.transactiondate >= date_trunc('week', CURRENT_DATE)
            GROUP BY w.childid
        `;

        const totalSpending = weekly.reduce((sum, r) => sum + Number(r.total || 0), 0);

        // ----------------------------------------
        // 🟩 1. TOP SPENDER
        // ----------------------------------------
        if (totalSpending === 0) {

    // check last week
    const lastWeek = await sql`
        SELECT SUM(t.amount) as total
        FROM "Transaction" t
        WHERE t."senderAccountId" = ANY(${accountIds})
        AND t.transactiontype = 'Payment'
        AND t.transactiondate >= date_trunc('week', CURRENT_DATE) - INTERVAL '1 week'
        AND t.transactiondate < date_trunc('week', CURRENT_DATE)
    `;

    const last = Number(lastWeek[0].total || 0);

    // ✅ Always return ONLY 2 messages
    if (last > 0) {
        return [
            { message: "No spending recorded this week" },
            { message: "Spending decreased compared to last week" },
        ];
    } else {
        return [
            { message: "No spending recorded this week" },
        ];
    }
} else {
            const sorted = weekly.sort((a, b) => Number(b.total) - Number(a.total));

            if (children.length === 1) {
                insights.push({
                    message: `${children[0].firstname} spent ${Number(sorted[0].total).toFixed(0)} SAR this week`
                });
            } else {
                const top = sorted[0];
                const second = sorted[1];

                if (second && Number(top.total) === Number(second.total)) {
                    insights.push({
                        message: "All children spent similar amounts this week"
                    });
                } else {
                    const name = children.find(c => c.childid === top.childid)?.firstname;
                    insights.push({
                        message: `${name} spent the most this week (${Number(top.total).toFixed(0)} SAR)`
                    });
                }
            }
        }

        // ----------------------------------------
        // 🟩 2. AVERAGE (only if >1 child & spending)
        // ----------------------------------------
        if (children.length > 1 && totalSpending > 0) {
            const avg = totalSpending / children.length;
            insights.push({
                message: `Average spending per child is ${avg.toFixed(0)} SAR`
            });
        }

        // ----------------------------------------
        // 🟩 3. CATEGORY (MOST IMPORTANT)
        // ----------------------------------------
        if (totalSpending > 0) {
            const categories = await sql`
                SELECT t.transactioncategory, SUM(t.amount) as total
                FROM "Transaction" t
                WHERE t."senderAccountId" = ANY(${accountIds})
                AND t.transactiontype = 'Payment'
                AND t.transactiondate >= date_trunc('week', CURRENT_DATE)
                GROUP BY t.transactioncategory
            `;

            let max = 0;
            let topCategory = null;

            categories.forEach(c => {
                const val = Number(c.total || 0);
                if (val > max) {
                    max = val;
                    topCategory = c.transactioncategory;
                }
            });

            if (topCategory && totalSpending > 0) {
                const percent = Math.round((max / totalSpending) * 100);

                insights.push({
                    message: `${percent}% of spending was on ${topCategory}`
                });
            } else {
                insights.push({
                    message: "Spending is balanced across categories"
                });
            }
        }

        // ----------------------------------------
        // 🟩 4. TOTAL
        // ----------------------------------------
        if (totalSpending > 0) {
            insights.push({
                message: `Total spending this week is ${totalSpending.toFixed(0)} SAR`
            });
        }

        // ----------------------------------------
        // 🟩 5. TREND (vs last week)
        // ----------------------------------------
        const lastWeek = await sql`
            SELECT SUM(t.amount) as total
            FROM "Transaction" t
            WHERE t."senderAccountId" = ANY(${accountIds})
            AND t.transactiontype = 'Payment'
            AND t.transactiondate >= date_trunc('week', CURRENT_DATE) - INTERVAL '1 week'
            AND t.transactiondate < date_trunc('week', CURRENT_DATE)
        `;

        const last = Number(lastWeek[0].total || 0);

          if (last > 0) {
            const change = ((totalSpending - last) / last) * 100;

            if (Math.abs(change) < 5) {
                insights.push({
                    message: "Spending remained consistent compared to last week"
                });
            } else if (change > 0) {
                insights.push({
                    message: `Spending increased by ${Math.round(change)}% compared to last week`
                });
            } else {
                insights.push({
                    message: `Spending decreased by ${Math.round(Math.abs(change))}% compared to last week`
                });
            }
        }

        // ----------------------------------------
        // LIMIT TO 5 INSIGHTS
        // ----------------------------------------
        return insights.slice(0, 5);

    } catch (error) {
        console.error("Parent Insights Error:", error);
        throw error;
    }
}