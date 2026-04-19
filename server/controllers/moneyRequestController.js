import { sql } from "../config/db.js";
import admin from "../config/firebaseAdmin.js";


// =============================================
// Child sends a money request (Request Money)
// =============================================
export const requestMoney = async (req, res) => {
  const { childId, amount, message } = req.body;

  if (!childId || !amount)
    return res.status(400).json({ error: "childId and amount are required" });

  try {
    // Get parent id for this child
    const parent = await sql`
      SELECT parentid FROM "Child" WHERE childid = ${childId}
    `;

    if (parent.length === 0)
      return res.status(404).json({ error: "Child not found" });

    const parentId = parent[0].parentid;

    const inserted = await sql`
      INSERT INTO "MoneyRequest" 
      (childId, parentId, amount, requestDescription, requestStatus, requestDate)
      VALUES (${childId}, ${parentId}, ${amount}, ${message}, 'Pending', NOW())
      RETURNING requestid
    `;

    const requestId = inserted[0].requestid;

// Notify PARENT
    await sql`
      INSERT INTO "Notification"(
        parentid, childid, message, type, moneyrequestid
      )
      VALUES (
        ${parentId}, ${childId},
        ${'Your child requested SAR ' + Number(amount).toFixed(2)},
        'MONEY_REQUEST',
        ${requestId}
      )
    `;

const tokens = await sql`
  SELECT "fcmtoken"
  FROM "DeviceToken"
  WHERE "childid" = ${childId}
`;

const tokenList = tokens.map(t => t.fcmtoken);

if (tokenList.length > 0) {
  await admin.messaging().sendEachForMulticast({
    tokens: tokenList,
    notification: {
      title: "Money Received 💰",
      body: `Your parent sent you SAR ${amt.toFixed(2)}`,
    },
  });
}    


    res.status(200).json({ message: "Request submitted successfully" });
  } catch (err) {
    console.error("❌ Error submitting money request:", err);
    res.status(500).json({ error: "Failed to submit request" });
  }
};



// // =============================================
// // Get all requests for a specific child
// // =============================================
// export const getRequestsByChild = async (req, res) => {
//   const { childId } = req.params;

//   try {
//     const requests = await sql`
//       SELECT 
//         r.requestid AS "requestId",
//         r.childid AS "childId",
//         r.parentid AS "parentId",
//         r.amount AS "amount",
//         r.requestdescription AS "requestDescription",
//         r.requeststatus AS "requestStatus",
//         r.requestdate AS "requestDate",
//         c.firstname AS "childName"
//       FROM "MoneyRequest" r
//       JOIN "Child" c ON r.childid = c.childid
//       WHERE r.childid = ${childId}
//       ORDER BY r.requestdate DESC;
//     `;

//     res.status(200).json(requests);
//   } catch (err) {
//     console.error("❌ Error fetching money requests:", err);
//     res.status(500).json({ error: "Failed to fetch requests" });
//   }
// };
// =============================================
// Get all requests for a specific child
// =============================================
export const getRequestsByChild = async (req, res) => {
  const { childId } = req.params;

  try {
    const requests = await sql`
      SELECT 
        r.requestid,
        r.childid,
        r.parentid,
        r.amount,
        r.requestdescription,
        r.requeststatus,
        r.requestdate,
        c.firstname AS "childName"
      FROM "MoneyRequest" r
      JOIN "Child" c ON r.childid = c.childid
      WHERE r.childid = ${childId}
      ORDER BY r.requestdate DESC;
    `;

    // ✅ تحويل الحقول يدوياً إلى camelCase لضمان توافق الفرونت إند
    const formattedRequests = requests.map(r => ({
      requestId: r.requestid,
      childId: r.childid,
      parentId: r.parentid,
      amount: r.amount,
      requestDescription: r.requestdescription,
      requestStatus: r.requeststatus, // تأكدي أن القيمة المخزنة هي "Pending" / "Approved" (أول حرف كبير)
      requestDate: r.requestdate,
      childName: r.childName
    }));

    res.status(200).json(formattedRequests);
  } catch (err) {
    console.error("❌ Error fetching money requests:", err);
    res.status(500).json({ error: "Failed to fetch requests" });
  }
};
// =============================================
// Update request status (Approve or Decline)
// =============================================
// export const updateRequestStatus = async (req, res) => {
//   const { requestId, status } = req.body;

//   const allowed = ["Approved", "Declined"];
//   if (!allowed.includes(status)) {
//     return res.status(400).json({ error: "Invalid status" });
//   }

//   try {
//     const result = await sql`
//       UPDATE "MoneyRequest"
//       SET requeststatus = ${status}
//       WHERE requestid = ${requestId}
//       RETURNING *;
//     `;

//     if (result.length === 0) {
//       return res.status(404).json({ error: "Request not found" });
//     }

//     res.status(200).json({ message: "Status updated", request: result[0] });
//   } catch (err) {
//     console.error("❌ Error updating request:", err);
//     res.status(500).json({ error: "Failed to update request" });
//   }
// };
// =============================================
// Update request status (Used for Decline OR marking Approved after transfer)
// =============================================
export const updateRequestStatus = async (req, res) => {
  const { requestId, status } = req.body;

  const allowed = ["Approved", "Declined"];
  if (!allowed.includes(status)) {
    return res.status(400).json({ error: "Invalid status" });
  }

  try {
    // 👇👇 التصحيح هنا: حذفنا علامات التنصيص "" حول requeststatus 👇👇
    const result = await sql`
      UPDATE "MoneyRequest"
      SET requeststatus = ${status}
      WHERE requestid = ${requestId}
      RETURNING *
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: "Request not found" });
    }

    const row = result[0];

    // Notify CHILD
    if (status === "Approved") {
      await sql`
        INSERT INTO "Notification"(
          parentid, childid, message, type, moneyrequestid
        )
        VALUES (
          ${row.parentid},
          ${row.childid},
          ${'Your request for SAR ' + Number(row.amount).toFixed(2) + ' was approved'},
          'REQUEST_APPROVED',
          ${requestId}
        )
      `;
    }

    if (status === "Declined") {
      await sql`
        INSERT INTO "Notification"(
          parentid, childid, message, type, moneyrequestid
        )
        VALUES (
          ${row.parentid},
          ${row.childid},
          ${'Your request for SAR ' + Number(row.amount).toFixed(2) + ' was declined'},
          'REQUEST_DECLINED',
          ${requestId}
        )
      `;
    }

    res.status(200).json({ message: "Status updated", request: row });
  } catch (err) {
    console.error("❌ Error updating request:", err);
    res.status(500).json({ error: "Failed to update request" });
  }
};
