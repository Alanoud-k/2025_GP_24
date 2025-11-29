// server/controllers/notificationController.js (ESM)

import { sql } from "../config/db.js";

/**
 * Get all notifications for a parent
 * GET /api/notifications/parent/:parentId
 */
export const getParentNotifications = async (req, res) => {
  const { parentId } = req.params;

  try {
    const rows = await sql`
      SELECT 
        n.notificationid AS "notificationId",
        n.message,
        n.type,
        n.moneyrequestid AS "requestId",
        n.createdat AS "createdAt",
        c.firstname AS "childName"
      FROM "Notification" n
      LEFT JOIN "Child" c ON c.childid = n.childid
      WHERE 
        n.parentid = ${parentId}
        AND n.type = 'MONEY_REQUEST'
      ORDER BY n.createdat DESC
    `;

    return res.status(200).json(rows);
  } catch (err) {
    console.error("❌ Error fetching notifications:", err);
    return res
      .status(500)
      .json({ error: "Failed to load notifications" });
  }
};
