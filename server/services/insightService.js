
// import { sql } from '../config/db.js';
// import OpenAI from "openai";

// export async function getChildInsights(
//     childId,
//     language = "en"
// )
//  {
//     try {

// const childData = await sql`
//     SELECT dob
//     FROM "Child"
//     WHERE childid = ${childId}
// `;

// let childAge = null;

// if (childData[0]?.dob) {
//     const birthDate = new Date(childData[0].dob);
//     const today = new Date();

//     childAge = today.getFullYear() - birthDate.getFullYear();

//     const monthDifference =
//         today.getMonth() - birthDate.getMonth();

//     if (
//         monthDifference < 0 ||
//         (monthDifference === 0 &&
//             today.getDate() < birthDate.getDate())
//     ) {
//         childAge--;
//     }
// }

//         const spendingAccounts = await sql`
//             SELECT a."accountid"
//             FROM "Account" a
//             JOIN "Wallet" w ON a."walletid" = w."walletid"
//             WHERE w."childid" = ${childId}
//             AND a."accounttype" = 'SpendingAccount'
//         `;

//         const savingAccount = await sql`
//     SELECT balance
//     FROM "Account" a
//     JOIN "Wallet" w 
//         ON a.walletid = w.walletid
//     WHERE w.childid = ${childId}
//     AND a.accounttype = 'SavingAccount'
// `;

// const savingBalance = Number(savingAccount[0]?.balance ?? 0);

// const goal = await sql`
//     SELECT 
//         g.goalname,
//         g.targetamount,
//         a.balance,
//         ROUND((a.balance / NULLIF(g.targetamount,0)) * 100, 0) AS progress
//     FROM "Goal" g
//     JOIN "Account" a 
//         ON g.accountid = a.accountid
//     WHERE g.childid = ${childId}
//     AND g.goalstatus = 'InProgress'
//     ORDER BY progress DESC
//     LIMIT 1
// `;

//         if (spendingAccounts.length === 0) return [];

//         const spendingAccountId = spendingAccounts[0].accountid;
//         const insights = [];

//         const earnedThisWeek = await sql`
//     SELECT SUM(amount) AS total
//     FROM "Transaction"
//     WHERE "receiverAccountId" = ${spendingAccountId}
//     AND "transactiontype"::text IN ('Allowance', 'Deposit', 'Transfer')
//     AND "transactiondate" >= CURRENT_DATE - INTERVAL '30 days'
// `;

// const earnedAmount = Number(earnedThisWeek[0]?.total ?? 0);

//         // 1️⃣ Weekly spending (Rolling 7 days)
//         const weeklySpending = await sql`
//             SELECT SUM("amount") AS total
//             FROM "Transaction"
//             WHERE "senderAccountId" = ${spendingAccountId}
//             AND "transactiondate" >= CURRENT_DATE - INTERVAL '30 days'
//             AND "transactiontype"::text = 'Payment'
//         `;

//         const totalSpending = Number(weeklySpending[0].total ?? 0);
//         console.log("💰 TOTAL SPENDING:", totalSpending);
//         if (totalSpending > 0) {
//             insights.push({
//                 type: "weekly",
//                 title: "insight_title_weekly_spending",
//                 message: "insight_msg_weekly_spending",
//                 value: totalSpending.toFixed(2)
//             });
//         } else {
//             insights.push({
//                 type: "empty",
//                 title: "insight_title_no_spending",
//                 message: "insight_msg_no_spending_week"
//             });
//         }

//         // 2️⃣ Category percentage
//         const categories = await sql`
//             SELECT "transactioncategory", SUM("amount") AS total
//             FROM "Transaction"
//             WHERE "senderAccountId" = ${spendingAccountId}
//             AND "transactiondate" >= CURRENT_DATE - INTERVAL '30 days'
//             AND "transactiontype"::text = 'Payment'
//             GROUP BY "transactioncategory"
//         `;

//         let maxCategory = null;
//         let maxAmount = 0;

//         categories.forEach(row => {
//             const amount = Number(row.total ?? 0);
//             if (amount > maxAmount) {
//                 maxAmount = amount;
//                 maxCategory = row.transactioncategory;
//             }
//         });
// console.log("📊 MAX CATEGORY:", maxCategory);
// console.log("📊 MAX AMOUNT:", maxAmount);
//         /*if (maxCategory && totalSpending > 0) {
//             const percentage = Math.round((maxAmount / totalSpending) * 100);
//             insights.push({
//                 type: "category",
//                 title: "insight_title_top_category",
//                 message: "insight_msg_top_category",
//                 value: `${percentage}`, // Percentage
//                 extraValue: maxCategory // Category Name
//             });
//         }*/
// console.log("🧪 CHECKING AI CONDITION");
// console.log("maxCategory exists:", !!maxCategory);
// console.log("totalSpending > 0:", totalSpending > 0);
//         if (maxCategory && totalSpending > 0) {
//             const percentage = Math.round((maxAmount / totalSpending) * 100);

// const goalName = goal[0]?.goalname ?? "none";

// const progress =
// goal.length > 0
// ? Math.round(
// (Number(goal[0].balance ?? 0) /
// Number(goal[0].targetamount ?? 1)) * 100
// )
// : 0;

// const summary = `
// Child age: ${childAge ?? "unknown"}

// Earned recently: ${earnedAmount} SAR

// Saved money: ${savingBalance} SAR

// Spent recently: ${totalSpending} SAR

// Top spending category: ${maxCategory ?? "none"}

// Goal name: ${goalName}

// Goal progress: ${progress}%
// `;

//            // ✅ call OpenAI
//             let aiMessage;

//             try {

// console.log("⚡ BEFORE AI CALL");
// aiMessage = await generateInsight(
//     summary,
//     "child",
//     language
// );console.log("⚡ AFTER AI CALL");

//             } catch (err) {
//                 console.error("AI Error:", err);

//             // ✅ fallback message using YOUR existing logic style
// aiMessage =
// `${percentage}% of your recent spending was on ${maxCategory}. Small changes can help you save more for your goals.`;            }
//                 insights.push({
//                 type: "ai-category",
//                 title: "Smart Insight",
//                 message: aiMessage
//             });
//         }

//         // 3️⃣ Self control
//         const yesterday = await sql`
//             SELECT COUNT(*) AS count
//             FROM "Transaction"
//             WHERE "senderAccountId" = ${spendingAccountId}
//             AND DATE("transactiondate") = CURRENT_DATE - INTERVAL '1 day'
//             AND "transactiontype"::text = 'Payment'
//         `;

//         const yesterdayCount = Number(yesterday[0].count ?? 0);
//         if (yesterdayCount === 0) {
//             insights.push({
//                 type: "self-control",
//                 title: "insight_title_self_control",
//                 message: "insight_msg_self_control"
//             });
//         }

//         // 5️⃣ Goal progress insight
//       /*  const goal = await sql`
//     SELECT 
//         g.goalname,
//         g.targetamount,
//         a.balance,
//         ROUND((a.balance / NULLIF(g.targetamount,0)) * 100, 0) AS progress
//     FROM "Goal" g
//     JOIN "Account" a 
//         ON g.accountid = a.accountid
//     WHERE g.childid = ${childId}
//     AND g.goalstatus = 'InProgress'
//     ORDER BY progress DESC
//     LIMIT 1
// `;*/

//         if (goal.length > 0) {
//             const goalName = goal[0].goalname;
//             const target = Number(goal[0].targetamount ?? 0);
//             const saved = Number(goal[0].balance ?? 0);

//             if (target > 0) {
//                 const progress = Math.round((saved / target) * 100);
//                 if (progress === 0) {
//                     insights.push({ 
//                         type: "goal-start", 
//                         title: "insight_title_start_saving", 
//                         message: "insight_msg_start_saving", 
//                         value: goalName 
//                     });
//                 } else if (progress >= 80 && progress < 100) {
//                     const remaining = target - saved;
//                     insights.push({ 
//                         type: "goal-close", 
//                         title: "insight_title_almost_there", 
//                         message: "insight_msg_almost_there", 
//                         value: remaining.toFixed(0),
//                         extraValue: goalName 
//                     });
//                 } else if (progress > 0 && progress < 80) {
//                     insights.push({ 
//                         type: "goal-progress", 
//                         title: "insight_title_goal_progress", 
//                         message: "insight_msg_goal_progress", 
//                         value: `${progress}`, 
//                         extraValue: goalName 
//                     });
//                 }
//             }
//         }

//        /* const earnedThisWeek = await sql`
//             SELECT SUM(amount) AS total
//             FROM "Transaction"
//             WHERE "receiverAccountId" = ${spendingAccountId}
//             AND "transactiontype"::text IN ('Allowance', 'Deposit', 'Transfer')
//             AND "transactiondate" >= CURRENT_DATE - INTERVAL '30 days'
//         `;*/

//        // const earnedAmount = Number(earnedThisWeek[0]?.total ?? 0);

//         // 4️⃣ Category change vs last week (Rolling 14 days vs 7 days)
//         const lastWeek = await sql`
//             SELECT "transactioncategory", SUM("amount") AS total
//             FROM "Transaction"
//             WHERE "senderAccountId" = ${spendingAccountId}
//             AND "transactiondate" >= CURRENT_DATE - INTERVAL '14 days'
//             AND "transactiondate" < CURRENT_DATE - INTERVAL '7 days'
//             AND "transactiontype"::text = 'Payment'
//             GROUP BY "transactioncategory"
//         `;

//         const lastWeekMap = {};
//         lastWeek.forEach(row => { lastWeekMap[row.transactioncategory] = Number(row.total ?? 0); });

//         categories.forEach(row => {
//             const current = Number(row.total ?? 0);
//             const previous = lastWeekMap[row.transactioncategory] ?? 0;

//             if (previous > 0) {
//                 const change = ((current - previous) / previous) * 100;
//                 if (change > 20) {
//                     insights.push({
//                         type: "increase",
//                         title: "insight_title_spending_increase",
//                         message: "insight_msg_spending_increase",
//                         value: row.transactioncategory,
//                         extraValue: `${Math.round(change)}`
//                     });
//                 }
//             }
//         });

//         return insights;
//     } catch (error) {
//         console.error("Insight Service Error:", error);
//         throw error;
//     }
// }

// export async function getGoalInsights(childId) {
//     const goals = await sql`
//         SELECT g.goalname, g.targetamount, a.balance
//         FROM "Goal" g
//         JOIN "Account" a ON g.accountid = a.accountid
//         WHERE g.childid = ${childId}
//         AND g.goalstatus = 'InProgress'
//         ORDER BY g.goalid DESC LIMIT 3
//     `;

//     const insights = [];
//     goals.forEach(goal => {
//         const goalName = goal.goalname;
//         const target = Number(goal.targetamount ?? 0);
//         const saved = Number(goal.balance ?? 0);

//         if (target <= 0) return;
//         const progress = Math.round((saved / target) * 100);

//         if (progress === 0) {
//             insights.push({ type: "goal-start", title: "Start Saving", message: `Start saving for your ${goalName}!` });
//         } else if (progress >= 80 && progress < 100) {
//             const remaining = target - saved;
//             insights.push({ type: "goal-close", title: "Almost There", message: `Only ${remaining.toFixed(0)} SAR left to reach your ${goalName}!` });
//         } else {
//             insights.push({ type: "goal-progress", title: "Goal Progress", message: `You're ${progress}% closer to your ${goalName}!` });
//         }
//     });

//     if (insights.length === 0) {
//         return [{ type: "empty", title: "No Goals Yet", message: "Start your first goal and track your progress here." }];
//     }
//     return insights;
// }

// export async function getChildChartData(childId, month, year, period = 'month') {
//     try {
//         const spendingAccounts = await sql`
//             SELECT a."accountid" FROM "Account" a JOIN "Wallet" w ON a."walletid" = w."walletid"
//             WHERE w."childid" = ${childId} AND a."accounttype" = 'SpendingAccount'
//         `;
//         if (spendingAccounts.length === 0) return {};
//         const spendingAccountId = spendingAccounts[0].accountid;

//         // Ensure "day" is declared if you intend to use it, or adjust the query.
//         // Assuming 'day' might be extracted from somewhere, but currently it's undefined in this scope if period='day'. 
//         // We will default to CURRENT_DATE logic to avoid crashes if 'day' is missing in arguments.
        
//         const categoriesData = await sql`
//             SELECT "transactioncategory", SUM("amount") AS total
//             FROM "Transaction"
//             WHERE "senderAccountId" = ${spendingAccountId}
//             AND "transactiontype"::text = 'Payment'
//             AND (
//                 (${period} = 'week' AND "transactiondate" >= date_trunc('week', CURRENT_DATE)) OR
//                 (${period} = 'month' AND EXTRACT(MONTH FROM "transactiondate") = ${month} AND EXTRACT(YEAR FROM "transactiondate") = ${year}) OR
//                 (${period} = 'year' AND EXTRACT(YEAR FROM "transactiondate") = ${year}) OR
//                 (${period} = 'day' AND DATE("transactiondate") = CURRENT_DATE)
//             )
//             GROUP BY "transactioncategory"
//         `;

//         const result = {};
//         categoriesData.forEach(row => {
//             if(row.transactioncategory && row.transactioncategory !== "Uncategorized") result[row.transactioncategory] = Number(row.total);
//         });
//         return result;
//     } catch (error) { console.error("Child Chart Error:", error); throw error; }
// }

// export async function getParentChartData(parentId, month, year, childName, period = 'month') {
//     try {
//         if (childName && childName !== "All") {
//             const categoriesData = await sql`
//                 SELECT t."transactioncategory" AS name, SUM(t."amount") AS total
//                 FROM "Transaction" t
//                 JOIN "Account" a ON t."senderAccountId" = a.accountid
//                 JOIN "Wallet" w ON a.walletid = w.walletid
//                 JOIN "Child" c ON w.childid = c.childid
//                 WHERE c.parentid = ${parentId}
//                 AND c.firstname = ${childName}
//                 AND t.transactiontype::text = 'Payment'
//                 AND (
//                     (${period} = 'day' AND DATE(t.transactiondate) = CURRENT_DATE) OR
//                     (${period} = 'week' AND t.transactiondate >= CURRENT_DATE - INTERVAL '7 days') OR
//                     (${period} = 'month' AND EXTRACT(MONTH FROM t.transactiondate) = ${month} AND EXTRACT(YEAR FROM t.transactiondate) = ${year}) OR
//                     (${period} = 'year' AND EXTRACT(YEAR FROM t.transactiondate) = ${year})
//                 )
//                 GROUP BY t."transactioncategory"
//             `;
//             const result = {};
//             categoriesData.forEach(row => {
//                 if(row.name && row.name !== "Uncategorized") result[row.name] = Number(row.total ?? 0);
//             });
//             return result;
//         } else {
//             const childrenSpending = await sql`
//                 SELECT c.firstname AS name, SUM(t.amount) AS total
//                 FROM "Transaction" t
//                 JOIN "Account" a ON t."senderAccountId" = a.accountid
//                 JOIN "Wallet" w ON a.walletid = w.walletid
//                 JOIN "Child" c ON w.childid = c.childid
//                 WHERE c.parentid = ${parentId}
//                 AND t.transactiontype::text = 'Payment'
//                 AND (
//                 (${period} = 'day' AND DATE("transactiondate") = CURRENT_DATE) OR
//                 (${period} = 'week' AND "transactiondate" >= date_trunc('week', CURRENT_DATE)) OR
//                 (${period} = 'month' AND EXTRACT(MONTH FROM "transactiondate") = ${month} AND EXTRACT(YEAR FROM "transactiondate") = ${year}) OR
//                 (${period} = 'year' AND EXTRACT(YEAR FROM "transactiondate") = ${year})
//             )
//                 GROUP BY c.firstname
//             `;
//             const result = {};
//             childrenSpending.forEach(row => {
//                 const cName = row.name || "Child"; 
//                 result[cName] = Number(row.total ?? 0);
//             });
//             return result;
//         }
//     } catch (error) { console.error("Parent Chart Error:", error); throw error; }
// }

// export async function getParentInsights(
//     parentId,
//     language = "en"
// ) {
//     try {
//         const insights = [];
//         const children = await sql`
//             SELECT c.childid, c.firstname
//             FROM "Child" c
//             WHERE c.parentid = ${parentId}
//         `;
//         console.log("🧪 CHILDREN:", children);
//         if (children.length === 0) {
//             return [
//                 { type: "empty", title: "No Children", message: "You haven’t added any children yet" },
//                 { type: "empty", title: "Get Started", message: "Add a child to start tracking spending" }
//             ];
//         }

//         const childIds = children.map(c => c.childid);
//         const accounts = await sql`
//             SELECT a.accountid, w.childid
//             FROM "Account" a
//             JOIN "Wallet" w ON a.walletid = w.walletid
//             WHERE w.childid = ANY(${childIds})
//             AND a.accounttype = 'SpendingAccount'
//         `;
//         console.log("🧪 ACCOUNTS:", accounts);
//         if (accounts.length === 0) {
//             return [{ type: "empty", title: "No Data", message: "No spending data available yet" }];
//         }

//         const accountIds = accounts.map(a => a.accountid);
//         const weekly = await sql`
//             SELECT w.childid, SUM(t.amount) as total
//             FROM "Transaction" t
//             JOIN "Account" a ON t."senderAccountId" = a.accountid
//             JOIN "Wallet" w ON a.walletid = w.walletid
//             WHERE a.accountid = ANY(${accountIds})
//             AND t.transactiontype::text = 'Payment'
//             AND t.transactiondate >= CURRENT_DATE - INTERVAL '30 days'
//             GROUP BY w.childid
//         `;
//         console.log("🧪 WEEKLY:", weekly);

//         const totalSpending = weekly.reduce((sum, r) => sum + Number(r.total || 0), 0);

//         if (totalSpending === 0) {
//             const lastWeek = await sql`
//                 SELECT SUM(t.amount) as total
//                 FROM "Transaction" t
//                 WHERE t."senderAccountId" = ANY(${accountIds})
//                 AND t.transactiontype::text = 'Payment'
//                 AND t.transactiondate >= CURRENT_DATE - INTERVAL '14 days'
//                 AND t.transactiondate < CURRENT_DATE - INTERVAL '7 days'
//             `;
//             const last = Number(lastWeek[0].total || 0);
//             if (last > 0) {
//                 return [
//                     { type: "empty", title: "No Activity", message: "No spending recorded in the last 7 days" },
//                     { type: "trend", title: "Spending Trend", message: "Spending decreased compared to last week" }
//                 ];
//             } else {
//                 return [{ type: "empty", title: "No Activity", message: "No spending recorded recently" }];
//             }
//         } else {
//             const sorted = weekly.sort((a, b) => Number(b.total) - Number(a.total));
//             if (children.length === 1) {
//                 insights.push({ type: "top-spender", title: "Recent Spending", message: `${children[0].firstname} spent ${Number(sorted[0].total).toFixed(0)} SAR recently` });
//             } else {
//                 const top = sorted[0];
//                 const second = sorted[1];
//                 if (second && Number(top.total) === Number(second.total)) {
//                     insights.push({ type: "top-spender", title: "Top Spender", message: "All children spent similar amounts recently" });
//                 } else {
//                     const name = children.find(c => c.childid === top.childid)?.firstname;
//                     insights.push({ type: "top-spender", title: "Top Spender", message: `${name} spent the most recently (${Number(top.total).toFixed(0)} SAR)` });
//                 }
//             }
//         }

//         if (children.length > 1 && totalSpending > 0) {
//             const avg = totalSpending / children.length;
//             insights.push({ type: "average", title: "Average Spending", message: `Average spending per child is ${avg.toFixed(0)} SAR` });
//         }

//         if (totalSpending > 0) {
//             const categories = await sql`
//                 SELECT t.transactioncategory, SUM(t.amount) as total
//                 FROM "Transaction" t
//                 WHERE t."senderAccountId" = ANY(${accountIds})
//                 AND t.transactiontype::text = 'Payment'
//                 AND t.transactiondate >= CURRENT_DATE - INTERVAL '30 days'
//                 GROUP BY t.transactioncategory
//             `;

//             let max = 0;
//             let topCategory = null;
//             categories.forEach(c => {
//                 const val = Number(c.total || 0);
//                 if (val > max) { max = val; topCategory = c.transactioncategory; }
//             });

//             if (topCategory && totalSpending > 0) {
//                 const percent = Math.round((max / totalSpending) * 100);

// const topChild = weekly.sort(
// (a, b) => Number(b.total) - Number(a.total)
// )[0];

// const topChildName =
// children.find(c => c.childid === topChild?.childid)?.firstname;

// //const percent = Math.round((max / totalSpending) * 100);

// const summary = `
// Number of children: ${children.length}

// Total family spending: ${totalSpending} SAR

// Top spending category: ${topCategory ?? "none"}

// Highest spending child: ${topChildName ?? "none"}

// Category percentage: ${percent}%

// Weekly spending:
// ${weekly.map(w => {
// const childName =
// children.find(c => c.childid === w.childid)?.firstname;

// return `${childName}: ${Number(w.total).toFixed(0)} SAR`;
// }).join("\n")}
// `;

// let aiMessage;

// try {
// console.log("⚡ BEFORE AI CALL");

// aiMessage = await generateInsight(
//     summary,
//     "parent",
//     language
// );
// console.log("⚡ AFTER AI CALL");} catch (err) {
//     console.error("AI Error:", err);

//     aiMessage = `${percent}% of spending is on ${topCategory}. Consider reviewing spending priorities.`;
// }
//                 insights.push({
//                     type: "ai-category",
//                     title: "Smart Insight",
//                     message: aiMessage
//                 });
//                 console.log(aiMessage);
//             } else {
//                 insights.push({ type: "category", title: "Top Category", message: "Spending is balanced across categories" });
//             }
            
//             insights.push({ type: "total", title: "Total Spent", message: `Total spending in the last 7 days is ${totalSpending.toFixed(0)} SAR` });
//         }

//         const lastWeek = await sql`
//             SELECT SUM(t.amount) as total
//             FROM "Transaction" t
//             WHERE t."senderAccountId" = ANY(${accountIds})
//             AND t.transactiontype::text = 'Payment'
//             AND t.transactiondate >= CURRENT_DATE - INTERVAL '14 days'
//             AND t.transactiondate < CURRENT_DATE - INTERVAL '7 days'
//         `;
//         const last = Number(lastWeek[0].total || 0);

//         if (last > 0) {
//             const change = ((totalSpending - last) / last) * 100;
//             if (Math.abs(change) < 5) {
//                 insights.push({ type: "trend", title: "Spending Trend", message: "Spending remained consistent compared to last week" });
//             } else if (change > 0) {
//                 insights.push({ type: "trend", title: "Spending Trend", message: `Spending increased by ${Math.round(change)}% compared to last week` });
//             } else {
//                 insights.push({ type: "trend", title: "Spending Trend", message: `Spending decreased by ${Math.round(Math.abs(change))}% compared to last week` });
//             }
//         }

//         return insights.slice(0, 5);
//     } catch (error) {
//         console.error("Parent Insights Error:", error);
//         throw error;
//     } 
// }


// const client = new OpenAI({
//   apiKey: process.env.OPENAI_API_KEY,
// });

// export async function generateInsight(summary, userType, language = "en") {

// console.log("🚀 generateInsight CALLED");

// const languageInstruction =
// language === "ar"
// ? "Write the response in Arabic."
// : "Write the response in English.";

// let rolePrompt = "";

// if (userType === "child") {

// rolePrompt = `
// You are a smart financial coach for children.

// Your job is to give ONE short personalized insight.

// RULES:
// - Use the Earn / Save / Spend model.
// - Focus on whichever area needs the most attention.
// - If spending is much higher than earning, focus on spending habits.
// - If the child earns money but saves very little, encourage saving.
// - If spending is healthy and saving is good, encourage the child positively.
// - If a goal exists, mention it naturally by name.
// - NEVER invent a goal that does not exist.
// - Match the tone to the child's age:
//   - younger kids → simpler encouraging words
//   - teens → more mature realistic wording
// - Keep response under 2 short sentences.
// - Maximum 25 words.
// - Sound supportive and human.
// - Avoid generic advice like "budget more".
// - Do NOT repeat exact numbers unless necessary.

// ${languageInstruction}

// Child data:
// ${summary}
// `;

// } else {

// rolePrompt = `
// You are a smart financial assistant for parents.

// Your job is to provide ONE short useful family spending insight.

// RULES:
// - Focus on meaningful spending patterns.
// - Mention trends or unusual spending behavior.
// - If one child spends much more than others, mention it naturally.
// - If spending is balanced, mention that positively.
// - Avoid sounding judgmental.
// - Avoid generic advice.
// - Keep the response under 2 short sentences.
// - Maximum 25 words.
// - Sound professional but warm.

// ${languageInstruction}

// Family data:
// ${summary}
// `;

// }

// console.log("⏱ Sending request to OpenAI...");

// const response = await client.responses.create({
// model: "gpt-4o-mini",
// input: rolePrompt,
// temperature: 0.7,
// });

// console.log("✅ OpenAI responded");

// return response.output_text || "Smart insight unavailable.";
// }

import { sql } from '../config/db.js';
import OpenAI from "openai";

export async function getChildInsights(
    childId,
    language = "en"
)
 {
    try {

const childData = await sql`
    SELECT dob
    FROM "Child"
    WHERE childid = ${childId}
`;

let childAge = null;

if (childData[0]?.dob) {
    const birthDate = new Date(childData[0].dob);
    const today = new Date();

    childAge = today.getFullYear() - birthDate.getFullYear();

    const monthDifference =
        today.getMonth() - birthDate.getMonth();

    if (
        monthDifference < 0 ||
        (monthDifference === 0 &&
            today.getDate() < birthDate.getDate())
    ) {
        childAge--;
    }
}

        const spendingAccounts = await sql`
            SELECT a."accountid"
            FROM "Account" a
            JOIN "Wallet" w ON a."walletid" = w."walletid"
            WHERE w."childid" = ${childId}
            AND a."accounttype" = 'SpendingAccount'
        `;

        const savingAccount = await sql`
    SELECT balance
    FROM "Account" a
    JOIN "Wallet" w 
        ON a.walletid = w.walletid
    WHERE w.childid = ${childId}
    AND a.accounttype = 'SavingAccount'
`;

const savingBalance = Number(savingAccount[0]?.balance ?? 0);

const goal = await sql`
    SELECT 
        g.goalname,
        g.targetamount,
        a.balance,
        ROUND((a.balance / NULLIF(g.targetamount,0)) * 100, 0) AS progress
    FROM "Goal" g
    JOIN "Account" a 
        ON g.accountid = a.accountid
    WHERE g.childid = ${childId}
    AND g.goalstatus = 'InProgress'
    ORDER BY progress DESC
    LIMIT 1
`;

        if (spendingAccounts.length === 0) return [];

        const spendingAccountId = spendingAccounts[0].accountid;
        const insights = [];

        const earnedThisWeek = await sql`
    SELECT SUM(amount) AS total
    FROM "Transaction"
    WHERE "receiverAccountId" = ${spendingAccountId}
    AND "transactiontype"::text IN ('Allowance', 'Deposit', 'Transfer')
    AND "transactiondate" >= CURRENT_DATE - INTERVAL '30 days'
`;

const earnedAmount = Number(earnedThisWeek[0]?.total ?? 0);

        // 1️⃣ Weekly spending (Rolling 7 days)
        const weeklySpending = await sql`
            SELECT SUM("amount") AS total
            FROM "Transaction"
            WHERE "senderAccountId" = ${spendingAccountId}
            AND "transactiondate" >= CURRENT_DATE - INTERVAL '30 days'
            AND "transactiontype"::text = 'Payment'
        `;

        const totalSpending = Number(weeklySpending[0].total ?? 0);
        console.log("💰 TOTAL SPENDING:", totalSpending);
        if (totalSpending > 0) {
            insights.push({
                type: "weekly",
                title: "insight_title_weekly_spending",
                message: "insight_msg_weekly_spending",
                value: totalSpending.toFixed(2)
            });
        } else {
            insights.push({
                type: "empty",
                title: "insight_title_no_spending",
                message: "insight_msg_no_spending_week"
            });
        }

        // 2️⃣ Category percentage
        const categories = await sql`
            SELECT "transactioncategory", SUM("amount") AS total
            FROM "Transaction"
            WHERE "senderAccountId" = ${spendingAccountId}
            AND "transactiondate" >= CURRENT_DATE - INTERVAL '30 days'
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
console.log("📊 MAX CATEGORY:", maxCategory);
console.log("📊 MAX AMOUNT:", maxAmount);
        /*if (maxCategory && totalSpending > 0) {
            const percentage = Math.round((maxAmount / totalSpending) * 100);
            insights.push({
                type: "category",
                title: "insight_title_top_category",
                message: "insight_msg_top_category",
                value: `${percentage}`, // Percentage
                extraValue: maxCategory // Category Name
            });
        }*/
console.log("🧪 CHECKING AI CONDITION");
console.log("maxCategory exists:", !!maxCategory);
console.log("totalSpending > 0:", totalSpending > 0);
        if (maxCategory && totalSpending > 0) {
            const percentage = Math.round((maxAmount / totalSpending) * 100);

const goalName = goal[0]?.goalname ?? "none";

const progress =
goal.length > 0
? Math.round(
(Number(goal[0].balance ?? 0) /
Number(goal[0].targetamount ?? 1)) * 100
)
: 0;

const summary = `
Child age: ${childAge ?? "unknown"}

Earned recently: ${earnedAmount} SAR

Saved money: ${savingBalance} SAR

Spent recently: ${totalSpending} SAR

Top spending category: ${maxCategory ?? "none"}

Goal name: ${goalName}

Goal progress: ${progress}%
`;

           // ✅ call OpenAI
            let aiMessage;

            try {

console.log("⚡ BEFORE AI CALL");
aiMessage = await generateInsight(
    summary,
    "child",
    language
);console.log("⚡ AFTER AI CALL");

            } catch (err) {
                console.error("AI Error:", err);

            // ✅ fallback message using YOUR existing logic style
aiMessage =
`${percentage}% of your recent spending was on ${maxCategory}. Small changes can help you save more for your goals.`;            }
                insights.push({
                type: "ai-category",
                title: "insight_title_smart_insight",
                message: aiMessage
            });
        }

        // 3️⃣ Self control
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
                title: "insight_title_self_control",
                message: "insight_msg_self_control"
            });
        }

        // 5️⃣ Goal progress insight
      /* const goal = await sql`
    SELECT 
        g.goalname,
        g.targetamount,
        a.balance,
        ROUND((a.balance / NULLIF(g.targetamount,0)) * 100, 0) AS progress
    FROM "Goal" g
    JOIN "Account" a 
        ON g.accountid = a.accountid
    WHERE g.childid = ${childId}
    AND g.goalstatus = 'InProgress'
    ORDER BY progress DESC
    LIMIT 1
`;*/

        if (goal.length > 0) {
            const goalName = goal[0].goalname;
            const target = Number(goal[0].targetamount ?? 0);
            const saved = Number(goal[0].balance ?? 0);

            if (target > 0) {
                const progress = Math.round((saved / target) * 100);
                if (progress === 0) {
                    insights.push({ 
                        type: "goal-start", 
                        title: "insight_title_start_saving", 
                        message: "insight_msg_start_saving", 
                        value: goalName 
                    });
                } else if (progress >= 80 && progress < 100) {
                    const remaining = target - saved;
                    insights.push({ 
                        type: "goal-close", 
                        title: "insight_title_almost_there", 
                        message: "insight_msg_almost_there", 
                        value: remaining.toFixed(0),
                        extraValue: goalName 
                    });
                } else if (progress > 0 && progress < 80) {
                    insights.push({ 
                        type: "goal-progress", 
                        title: "insight_title_goal_progress", 
                        message: "insight_msg_goal_progress", 
                        value: `${progress}`, 
                        extraValue: goalName 
                    });
                }
            }
        }

       /* const earnedThisWeek = await sql`
            SELECT SUM(amount) AS total
            FROM "Transaction"
            WHERE "receiverAccountId" = ${spendingAccountId}
            AND "transactiontype"::text IN ('Allowance', 'Deposit', 'Transfer')
            AND "transactiondate" >= CURRENT_DATE - INTERVAL '30 days'
        `;*/

       // const earnedAmount = Number(earnedThisWeek[0]?.total ?? 0);

        // 4️⃣ Category change vs last week (Rolling 14 days vs 7 days)
        const lastWeek = await sql`
            SELECT "transactioncategory", SUM("amount") AS total
            FROM "Transaction"
            WHERE "senderAccountId" = ${spendingAccountId}
            AND "transactiondate" >= CURRENT_DATE - INTERVAL '14 days'
            AND "transactiondate" < CURRENT_DATE - INTERVAL '7 days'
            AND "transactiontype"::text = 'Payment'
            GROUP BY "transactioncategory"
        `;

        const lastWeekMap = {};
        lastWeek.forEach(row => { lastWeekMap[row.transactioncategory] = Number(row.total ?? 0); });

        categories.forEach(row => {
            const current = Number(row.total ?? 0);
            const previous = lastWeekMap[row.transactioncategory] ?? 0;

            if (previous > 0) {
                const change = ((current - previous) / previous) * 100;
                if (change > 20) {
                    insights.push({
                        type: "increase",
                        title: "insight_title_spending_increase",
                        message: "insight_msg_spending_increase",
                        value: row.transactioncategory,
                        extraValue: `${Math.round(change)}`
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
        SELECT g.goalname, g.targetamount, a.balance
        FROM "Goal" g
        JOIN "Account" a ON g.accountid = a.accountid
        WHERE g.childid = ${childId}
        AND g.goalstatus = 'InProgress'
        ORDER BY g.goalid DESC LIMIT 3
    `;

    const insights = [];
    goals.forEach(goal => {
        const goalName = goal.goalname;
        const target = Number(goal.targetamount ?? 0);
        const saved = Number(goal.balance ?? 0);

        if (target <= 0) return;
        const progress = Math.round((saved / target) * 100);

        if (progress === 0) {
            insights.push({ type: "goal-start", title: "insight_title_start_saving", message: "insight_msg_start_saving", value: goalName });
        } else if (progress >= 80 && progress < 100) {
            const remaining = target - saved;
            insights.push({ type: "goal-close", title: "insight_title_almost_there", message: "insight_msg_almost_there", value: remaining.toFixed(0), extraValue: goalName });
        } else {
            insights.push({ type: "goal-progress", title: "insight_title_goal_progress", message: "insight_msg_goal_progress", value: `${progress}`, extraValue: goalName });
        }
    });

    if (insights.length === 0) {
        return [{ type: "empty", title: "insight_title_no_goals_yet", message: "insight_msg_no_goals_yet" }];
    }
    return insights;
}

export async function getChildChartData(childId, month, year, period = 'month') {
    try {
        const spendingAccounts = await sql`
            SELECT a."accountid" FROM "Account" a JOIN "Wallet" w ON a."walletid" = w."walletid"
            WHERE w."childid" = ${childId} AND a."accounttype" = 'SpendingAccount'
        `;
        if (spendingAccounts.length === 0) return {};
        const spendingAccountId = spendingAccounts[0].accountid;

        // Ensure "day" is declared if you intend to use it, or adjust the query.
        // Assuming 'day' might be extracted from somewhere, but currently it's undefined in this scope if period='day'. 
        // We will default to CURRENT_DATE logic to avoid crashes if 'day' is missing in arguments.
        
        const categoriesData = await sql`
            SELECT "transactioncategory", SUM("amount") AS total
            FROM "Transaction"
            WHERE "senderAccountId" = ${spendingAccountId}
            AND "transactiontype"::text = 'Payment'
            AND (
                (${period} = 'week' AND "transactiondate" >= date_trunc('week', CURRENT_DATE)) OR
                (${period} = 'month' AND EXTRACT(MONTH FROM "transactiondate") = ${month} AND EXTRACT(YEAR FROM "transactiondate") = ${year}) OR
                (${period} = 'year' AND EXTRACT(YEAR FROM "transactiondate") = ${year}) OR
                (${period} = 'day' AND DATE("transactiondate") = CURRENT_DATE)
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
                    (${period} = 'day' AND DATE(t.transactiondate) = CURRENT_DATE) OR
                    (${period} = 'week' AND t.transactiondate >= CURRENT_DATE - INTERVAL '7 days') OR
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
                (${period} = 'day' AND DATE("transactiondate") = CURRENT_DATE) OR
                (${period} = 'week' AND "transactiondate" >= date_trunc('week', CURRENT_DATE)) OR
                (${period} = 'month' AND EXTRACT(MONTH FROM "transactiondate") = ${month} AND EXTRACT(YEAR FROM "transactiondate") = ${year}) OR
                (${period} = 'year' AND EXTRACT(YEAR FROM "transactiondate") = ${year})
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

export async function getParentInsights(
    parentId,
    language = "en"
) {
    try {
        const insights = [];
        const children = await sql`
            SELECT c.childid, c.firstname
            FROM "Child" c
            WHERE c.parentid = ${parentId}
        `;
        console.log("🧪 CHILDREN:", children);
        if (children.length === 0) {
            return [
                { type: "empty", title: "insight_title_no_children", message: "insight_msg_no_children" },
                { type: "empty", title: "insight_title_get_started", message: "insight_msg_get_started" }
            ];
        }

        const childIds = children.map(c => c.childid);
        const accounts = await sql`
            SELECT a.accountid, w.childid
            FROM "Account" a
            JOIN "Wallet" w ON a.walletid = w.walletid
            WHERE w.childid = ANY(${childIds})
            AND a.accounttype = 'SpendingAccount'
        `;
        console.log("🧪 ACCOUNTS:", accounts);
        if (accounts.length === 0) {
            return [{ type: "empty", title: "insight_title_no_data", message: "insight_msg_no_data" }];
        }

        const accountIds = accounts.map(a => a.accountid);
        const weekly = await sql`
            SELECT w.childid, SUM(t.amount) as total
            FROM "Transaction" t
            JOIN "Account" a ON t."senderAccountId" = a.accountid
            JOIN "Wallet" w ON a.walletid = w.walletid
            WHERE a.accountid = ANY(${accountIds})
            AND t.transactiontype::text = 'Payment'
            AND t.transactiondate >= CURRENT_DATE - INTERVAL '30 days'
            GROUP BY w.childid
        `;
        console.log("🧪 WEEKLY:", weekly);

        const totalSpending = weekly.reduce((sum, r) => sum + Number(r.total || 0), 0);

        if (totalSpending === 0) {
            const lastWeek = await sql`
                SELECT SUM(t.amount) as total
                FROM "Transaction" t
                WHERE t."senderAccountId" = ANY(${accountIds})
                AND t.transactiontype::text = 'Payment'
                AND t.transactiondate >= CURRENT_DATE - INTERVAL '14 days'
                AND t.transactiondate < CURRENT_DATE - INTERVAL '7 days'
            `;
            const last = Number(lastWeek[0].total || 0);
            if (last > 0) {
                return [
                    { type: "empty", title: "insight_title_no_activity", message: "insight_msg_no_activity_7d" },
                    { type: "trend", title: "insight_title_spending_trend", message: "insight_msg_trend_decreased" }
                ];
            } else {
                return [{ type: "empty", title: "insight_title_no_activity", message: "insight_msg_no_activity_recent" }];
            }
        } else {
            const sorted = weekly.sort((a, b) => Number(b.total) - Number(a.total));
            if (children.length === 1) {
                insights.push({ type: "top-spender", title: "insight_title_recent_spending", message: "insight_msg_recent_spending", value: children[0].firstname, extraValue: Number(sorted[0].total).toFixed(0) });
            } else {
                const top = sorted[0];
                const second = sorted[1];
                if (second && Number(top.total) === Number(second.total)) {
                    insights.push({ type: "top-spender", title: "insight_title_top_spender", message: "insight_msg_top_spender_similar" });
                } else {
                    const name = children.find(c => c.childid === top.childid)?.firstname;
                    insights.push({ type: "top-spender", title: "insight_title_top_spender", message: "insight_msg_top_spender", value: name, extraValue: Number(top.total).toFixed(0) });
                }
            }
        }

        if (children.length > 1 && totalSpending > 0) {
            const avg = totalSpending / children.length;
            insights.push({ type: "average", title: "insight_title_average_spending", message: "insight_msg_average_spending", value: avg.toFixed(0) });
        }

        if (totalSpending > 0) {
            const categories = await sql`
                SELECT t.transactioncategory, SUM(t.amount) as total
                FROM "Transaction" t
                WHERE t."senderAccountId" = ANY(${accountIds})
                AND t.transactiontype::text = 'Payment'
                AND t.transactiondate >= CURRENT_DATE - INTERVAL '30 days'
                GROUP BY t.transactioncategory
            `;

            let max = 0;
            let topCategory = null;
            categories.forEach(c => {
                const val = Number(c.total || 0);
                if (val > max) { max = val; topCategory = c.transactioncategory; }
            });

            if (topCategory && totalSpending > 0) {
                const percent = Math.round((max / totalSpending) * 100);

const topChild = weekly.sort(
(a, b) => Number(b.total) - Number(a.total)
)[0];

const topChildName =
children.find(c => c.childid === topChild?.childid)?.firstname;

//const percent = Math.round((max / totalSpending) * 100);

const summary = `
Number of children: ${children.length}

Total family spending: ${totalSpending} SAR

Top spending category: ${topCategory ?? "none"}

Highest spending child: ${topChildName ?? "none"}

Category percentage: ${percent}%

Weekly spending:
${weekly.map(w => {
const childName =
children.find(c => c.childid === w.childid)?.firstname;

return `${childName}: ${Number(w.total).toFixed(0)} SAR`;
}).join("\n")}
`;

let aiMessage;

try {
console.log("⚡ BEFORE AI CALL");

aiMessage = await generateInsight(
    summary,
    "parent",
    language
);
console.log("⚡ AFTER AI CALL");} catch (err) {
    console.error("AI Error:", err);

    aiMessage = `${percent}% of spending is on ${topCategory}. Consider reviewing spending priorities.`;
}
                insights.push({
                    type: "ai-category",
                    title: "insight_title_smart_insight",
                    message: aiMessage
                });
                console.log(aiMessage);
            } else {
                insights.push({ type: "category", title: "insight_title_top_category", message: "insight_msg_top_category_balanced" });
            }
            
            insights.push({ type: "total", title: "insight_title_total_spent", message: "insight_msg_total_spent", value: totalSpending.toFixed(0) });
        }

        const lastWeek = await sql`
            SELECT SUM(t.amount) as total
            FROM "Transaction" t
            WHERE t."senderAccountId" = ANY(${accountIds})
            AND t.transactiontype::text = 'Payment'
            AND t.transactiondate >= CURRENT_DATE - INTERVAL '14 days'
            AND t.transactiondate < CURRENT_DATE - INTERVAL '7 days'
        `;
        const last = Number(lastWeek[0].total || 0);

        if (last > 0) {
            const change = ((totalSpending - last) / last) * 100;
            if (Math.abs(change) < 5) {
                insights.push({ type: "trend", title: "insight_title_spending_trend", message: "insight_msg_trend_consistent" });
            } else if (change > 0) {
                insights.push({ type: "trend", title: "insight_title_spending_trend", message: "insight_msg_trend_increased", value: `${Math.round(change)}` });
            } else {
                insights.push({ type: "trend", title: "insight_title_spending_trend", message: "insight_msg_trend_decreased_percent", value: `${Math.round(Math.abs(change))}` });
            }
        }

        return insights.slice(0, 5);
    } catch (error) {
        console.error("Parent Insights Error:", error);
        throw error;
    } 
}


const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export async function generateInsight(summary, userType, language = "en") {

console.log("🚀 generateInsight CALLED");

const languageInstruction =
language === "ar"
? "Write the response in Arabic."
: "Write the response in English.";

let rolePrompt = "";

if (userType === "child") {

rolePrompt = `
You are a smart financial coach for children.

Your job is to give ONE short personalized insight.

RULES:
- Use the Earn / Save / Spend model.
- Focus on whichever area needs the most attention.
- If spending is much higher than earning, focus on spending habits.
- If the child earns money but saves very little, encourage saving.
- If spending is healthy and saving is good, encourage the child positively.
- If a goal exists, mention it naturally by name.
- NEVER invent a goal that does not exist.
- Match the tone to the child's age:
  - younger kids → simpler encouraging words
  - teens → more mature realistic wording
- Keep response under 2 short sentences.
- Maximum 25 words.
- Sound supportive and human.
- Avoid generic advice like "budget more".
- Do NOT repeat exact numbers unless necessary.

${languageInstruction}

Child data:
${summary}
`;

} else {

rolePrompt = `
You are a smart financial assistant for parents.

Your job is to provide ONE short useful family spending insight.

RULES:
- Focus on meaningful spending patterns.
- Mention trends or unusual spending behavior.
- If one child spends much more than others, mention it naturally.
- If spending is balanced, mention that positively.
- Avoid sounding judgmental.
- Avoid generic advice.
- Keep the response under 2 short sentences.
- Maximum 25 words.
- Sound professional but warm.

${languageInstruction}

Family data:
${summary}
`;

}

console.log("⏱ Sending request to OpenAI...");

const response = await client.responses.create({
model: "gpt-4o-mini",
input: rolePrompt,
temperature: 0.7,
});

console.log("✅ OpenAI responded");

return response.output_text || "Smart insight unavailable.";
}