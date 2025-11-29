// server/controllers/notificationController.js

import { sql } from "../config/db.js";

/* ============================================================
   PARENT – GET NOTIFICATIONS
   (Only MONEY_REQUEST for parents)
============================================================ */
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
        c.firstname AS "childName",
        n.isread
      FROM "Notification" n
      LEFT JOIN "Child" c ON c.childid = n.childid
      WHERE n.parentid = ${parentId}
        AND n.type = 'MONEY_REQUEST'
      ORDER BY n.createdat DESC
    `;

    return res.status(200).json(rows);
  } catch (err) {
    console.error("❌ Error fetching parent notifications:", err);
    return res.status(500).json({ error: "Failed to load notifications" });
  }
};

/* ============================================================
   CHILD – GET NOTIFICATIONS
============================================================ */
export const getChildNotifications = async (req, res) => {
  const { childId } = req.params;

  try {
    const rows = await sql`
      SELECT 
        n.notificationid AS "notificationId",
        n.message,
        n.type,
        n.moneyrequestid AS "requestId",
        n.createdat AS "createdAt",
        n.isread
      FROM "Notification" n
      WHERE n.childid = ${childId}
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

/* ============================================================
   UNREAD COUNTS
============================================================ */
export const getUnreadCountParent = async (req, res) => {
  const { parentId } = req.params;

  try {
    const row = await sql`
      SELECT COUNT(*) AS unread
      FROM "Notification"
      WHERE parentid = ${parentId}
        AND isread = FALSE
        AND type = 'MONEY_REQUEST'
    `;

    res.status(200).json({ unread: Number(row[0].unread) });
  } catch (err) {
    console.error("❌ Parent unread count error:", err);
    res.status(500).json({ error: "Failed" });
  }
};

export const getUnreadCountChild = async (req, res) => {
  const { childId } = req.params;

  try {
    const row = await sql`
      SELECT COUNT(*) AS unread
      FROM "Notification"
      WHERE childid = ${childId}
        AND isread = FALSE
        AND type IN (
          'REQUEST_APPROVED',
          'REQUEST_DECLINED',
          'MONEY_TRANSFER'
        )
    `;

    res.status(200).json({ unread: Number(row[0].unread) });
  } catch (err) {
    console.error("❌ Child unread count error:", err);
    res.status(500).json({ error: "Failed" });
  }
};

/* ============================================================
   MARK READ (PARENT + CHILD)
============================================================ */

/// NEW:
export const markParentNotificationsRead = async (req, res) => {
  const { parentId } = req.params;

  try {
    await sql`
      UPDATE "Notification"
      SET isread = TRUE
      WHERE parentid = ${parentId}
        AND type = 'MONEY_REQUEST'
    `;
    res.sendStatus(200);
  } catch (err) {
    console.error("❌ Parent mark-read error:", err);
    res.status(500).json({ error: "Failed to update parent notifications" });
  }
};

export const markChildNotificationsRead = async (req, res) => {
  const { childId } = req.params;

  try {
    await sql`
      UPDATE "Notification"
      SET isread = TRUE
      WHERE childid = ${childId}
    `;
    res.sendStatus(200);
  } catch (err) {
    console.error("❌ Child mark-read error:", err);
    res.status(500).json({ error: "Failed to update notifications" });
  }
};
