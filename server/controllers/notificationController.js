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

/////////////////////////////////////

export const getChildNotifications = async (req, res) => {
  const { childId } = req.params;

  try {
    const rows = await sql`
      SELECT 
        n.notificationid AS "notificationId",
        n.message,
        n.type,
        n.moneyrequestid AS "requestId",
        n.createdat AS "createdAt"
      FROM "Notification" n
      WHERE 
        n.childid = ${childId}
        AND n.type IN (
          'REQUEST_APPROVED',
          'REQUEST_DECLINED',
          'MONEY_TRANSFER'
        )
      ORDER BY n.createdat DESC
    `;

    return res.status(200).json(rows);
  } catch (err) {
    console.error("❌ Error fetching child notifications:", err);
    return res.status(500).json({ error: "Failed to load notifications" });
  }
};
/////////////////////////////////////

/* -----------------------------------------
   UNREAD COUNTS
-------------------------------------------*/
export const getUnreadCountParent = async (req, res) => {
  const { parentId } = req.params;

  try {
    const row = await sql`
      SELECT COUNT(*) AS unread
      FROM "Notification"
      WHERE parentid = ${parentId} AND isread = FALSE
        AND type IN ('MONEY_REQUEST')
    `;

    res.status(200).json({ unread: Number(row[0].unread) });
  } catch (err) {
    console.error("❌ Error unread count:", err);
    res.status(500).json({ error: "Failed" });
  }
};

export const getUnreadCountChild = async (req, res) => {
  const { childId } = req.params;

  try {
    const row = await sql`
      SELECT COUNT(*) AS unread
      FROM "Notification"
      WHERE childid = ${childId} AND isread = FALSE
        AND type IN ('REQUEST_APPROVED','REQUEST_DECLINED','MONEY_TRANSFER')
    `;

    res.status(200).json({ unread: Number(row[0].unread) });
  } catch (err) {
    console.error("❌ Error unread count:", err);
    res.status(500).json({ error: "Failed" });
  }
};

/* -----------------------------------------
   MARK notification as read
-------------------------------------------*/
export const markNotificationRead = async (req, res) => {
  const { notificationId } = req.body;

  try {
    await sql`
      UPDATE "Notification"
      SET isread = TRUE
      WHERE notificationid = ${notificationId}
    `;

    res.status(200).json({ success: true });
  } catch (err) {
    console.error("❌ Error marking read:", err);
    res.status(500).json({ error: "Failed to mark as read" });
  }
};