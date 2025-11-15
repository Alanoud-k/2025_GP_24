import { sql } from "../config/db.js";


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

    // Insert money request
    await sql`
      INSERT INTO "MoneyRequest" 
      (childId, parentId, amount, requestDescription, requestStatus, requestDate)
      VALUES (${childId}, ${parentId}, ${amount}, ${message}, 'Pending', NOW())
    `;

    res.status(200).json({ message: "Request submitted successfully" });
  } catch (err) {
    console.error("❌ Error submitting money request:", err);
    res.status(500).json({ error: "Failed to submit request" });
  }
};



// =============================================
// Get all requests for a specific child
// =============================================
export const getRequestsByChild = async (req, res) => {
  const { childId } = req.params;

  try {
    const requests = await sql`
      SELECT 
        r.requestid AS "requestId",
        r.childid AS "childId",
        r.parentid AS "parentId",
        r.amount AS "amount",
        r.requestdescription AS "requestDescription",
        r.requeststatus AS "requestStatus",
        r.requestdate AS "requestDate",
        c.firstname AS "childName"
      FROM "MoneyRequest" r
      JOIN "Child" c ON r.childid = c.childid
      WHERE r.childid = ${childId}
      ORDER BY r.requestdate DESC;
    `;

    res.status(200).json(requests);
  } catch (err) {
    console.error("❌ Error fetching money requests:", err);
    res.status(500).json({ error: "Failed to fetch requests" });
  }
};
// =============================================
// Update request status (Approve or Decline)
// =============================================
export const updateRequestStatus = async (req, res) => {
  const { requestId, status } = req.body;

  const allowed = ["Approved", "Declined"];
  if (!allowed.includes(status)) {
    return res.status(400).json({ error: "Invalid status" });
  }

  try {
    const result = await sql`
      UPDATE "MoneyRequest"
      SET requeststatus = ${status}
      WHERE requestid = ${requestId}
      RETURNING *;
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: "Request not found" });
    }

    res.status(200).json({ message: "Status updated", request: result[0] });
  } catch (err) {
    console.error("❌ Error updating request:", err);
    res.status(500).json({ error: "Failed to update request" });
  }
};
