// // server/controllers/notificationController.js

// import { sql } from "../config/db.js";

// /* ============================================================
//    PARENT – GET NOTIFICATIONS
//    (Only MONEY_REQUEST for parents)
// ============================================================ */
// export const getParentNotifications = async (req, res) => {
//   const { parentId } = req.params;

//   try {
//     const rows = await sql`
//       SELECT 
//         n.notificationid AS "notificationId",
//         n.message,
//         n.type,
//         n.moneyrequestid AS "requestId",
//         n.createdat AS "createdAt",
//         c.firstname AS "childName",
//         n.isread
//       FROM "Notification" n
//       LEFT JOIN "Child" c ON c.childid = n.childid
//       WHERE n.parentid = ${parentId} AND n.type IN ('MONEY_REQUEST', 'REWARD_REDEEMED')
//       ORDER BY n.createdat DESC
//     `;

//     return res.status(200).json(rows);
//   } catch (err) {
//     console.error("❌ Error fetching parent notifications:", err);
//     return res.status(500).json({ error: "Failed to load notifications" });
//   }
// };

// // /* ============================================================
// //    CHILD – GET NOTIFICATIONS
// // ============================================================ */
// // export const getChildNotifications = async (req, res) => {
// //   const { childId } = req.params;

// //   try {
// //     const rows = await sql`
// //       SELECT 
// //         n.notificationid AS "notificationId",
// //         n.message,
// //         n.type,
// //         n.moneyrequestid AS "requestId",
// //         n.createdat AS "createdAt",
// //         n.isread
// //       FROM "Notification" n
// //       WHERE n.childid = ${childId}
// //         AND n.type IN (
// //           'REQUEST_APPROVED',
// //           'REQUEST_DECLINED',
// //           'MONEY_TRANSFER'
// //         )
// //       ORDER BY n.createdat DESC
// //     `;

// //     return res.status(200).json(rows);
// //   } catch (err) {
// //     console.error("❌ Error fetching child notifications:", err);
// //     return res.status(500).json({ error: "Failed to load notifications" });
// //   }
// // };

// /* ============================================================
//    CHILD – GET NOTIFICATIONS
// ============================================================ */
// export const getChildNotifications = async (req, res) => {
//   const { childId } = req.params;

//   try {
//     const rows = await sql`
//       SELECT 
//         n.notificationid AS "notificationId",
//         n.message,
//         n.type,
//         n.moneyrequestid AS "requestId",
//         n.createdat AS "createdAt",
//         n.isread
//       FROM "Notification" n
//       WHERE n.childid = ${childId}
//         AND n.type IN (
//           'REQUEST_APPROVED',
//           'REQUEST_DECLINED',
//           'MONEY_TRANSFER',
//           'CHORE_ASSIGNED',  -- 👈 جديد
//           'CHORE_APPROVED'   -- 👈 جديد
//         )
//       ORDER BY n.createdat DESC
//     `;

//     return res.status(200).json(rows);
//   } catch (err) {
//     console.error("❌ Error fetching child notifications:", err);
//     return res.status(500).json({ error: "Failed to load notifications" });
//   }
// };

// /* ============================================================
//    UNREAD COUNTS
// ============================================================ */
// export const getUnreadCountParent = async (req, res) => {
//   const { parentId } = req.params;

//   try {
//     const row = await sql`
//       SELECT COUNT(*) AS unread
//       FROM "Notification"
//       WHERE parentid = ${parentId} AND isread = FALSE AND type IN ('MONEY_REQUEST', 'REWARD_REDEEMED')
//     `;

//     res.status(200).json({ unread: Number(row[0].unread) });
//   } catch (err) {
//     console.error("❌ Parent unread count error:", err);
//     res.status(500).json({ error: "Failed" });
//   }
// };

// export const getUnreadCountChild = async (req, res) => {
//   const { childId } = req.params;

//   try {
//     const row = await sql`
//       SELECT COUNT(*) AS unread
//       FROM "Notification"
//       WHERE childid = ${childId}
//         AND isread = FALSE
//         AND type IN (
//           'REQUEST_APPROVED',
//           'REQUEST_DECLINED',
//           'MONEY_TRANSFER'
//           'CHORE_ASSIGNED',  -- 👈 جديد
//           'CHORE_APPROVED'   -- 👈 جديد
//         )
//     `;

//     res.status(200).json({ unread: Number(row[0].unread) });
//   } catch (err) {
//     console.error("❌ Child unread count error:", err);
//     res.status(500).json({ error: "Failed" });
//   }
// };

// /* ============================================================
//    MARK READ (PARENT + CHILD)
// ============================================================ */

// /// NEW:
// export const markParentNotificationsRead = async (req, res) => {
//   const { parentId } = req.params;

//   try {
//     await sql`
//       UPDATE "Notification"
//       SET isread = TRUE
//       WHERE parentid = ${parentId} AND type IN ('MONEY_REQUEST', 'REWARD_REDEEMED')
//     `;
//     res.sendStatus(200);
//   } catch (err) {
//     console.error("❌ Parent mark-read error:", err);
//     res.status(500).json({ error: "Failed to update parent notifications" });
//   }
// };

// export const markChildNotificationsRead = async (req, res) => {
//   const { childId } = req.params;

//   try {
//     await sql`
//       UPDATE "Notification"
//       SET isread = TRUE
//       WHERE childid = ${childId}
//     `;
//     res.sendStatus(200);
//   } catch (err) {
//     console.error("❌ Child mark-read error:", err);
//     res.status(500).json({ error: "Failed to update notifications" });
//   }
// };

// export const createNotification = async (
//   parentId,
//   childId,
//   type,
//   message,
//   moneyRequestId = null,
//   choreId = null // 👈 معامل جديد للتشورز
// ) => {
//   try {
//     await sql`
//       INSERT INTO "Notification" (
//         "parentid", 
//         "childid", 
//         "type", 
//         "message", 
//         "moneyrequestid", 
//         "isread", 
//         "createdat"
//       )
//       VALUES (
//         ${parentId}, 
//         ${childId}, 
//         ${type}, 
//         ${message}, 
//         ${moneyRequestId}, 
//         FALSE, 
//         CURRENT_TIMESTAMP
//       )
//     `;
//     console.log(`🔔 Notification created for Parent ${parentId}: ${message}`);
//   } catch (err) {
//     console.error("❌ Failed to create notification:", err);
//   }
// };

import { sql } from "../config/db.js";

// === PARENT NOTIFICATIONS ===
export const getParentNotifications = async (req, res) => {
  const { parentId } = req.params;
  try {
    const rows = await sql`
      SELECT 
        n.notificationid AS "notificationId", n.message, n.type,
        n.moneyrequestid AS "requestId", n.createdat AS "createdAt",
        c.firstname AS "childName", n.isread
      FROM "Notification" n
      LEFT JOIN "Child" c ON c.childid = n.childid
      WHERE n.parentid = ${parentId} 
      AND n.type IN ('MONEY_REQUEST', 'REWARD_REDEEMED', 'CHORE_COMPLETED') -- ✅ تم إضافة المهام المكتملة
      ORDER BY n.createdat DESC
    `;
    return res.status(200).json(rows);
  } catch (err) {
    return res.status(500).json({ error: "Failed to load notifications" });
  }
};

export const getUnreadCountParent = async (req, res) => {
  const { parentId } = req.params;
  try {
    const row = await sql`
      SELECT COUNT(*) AS unread FROM "Notification"
      WHERE parentid = ${parentId} AND isread = FALSE 
      AND type IN ('MONEY_REQUEST', 'REWARD_REDEEMED', 'CHORE_COMPLETED') -- ✅
    `;
    res.status(200).json({ unread: Number(row[0].unread) });
  } catch (err) {
    res.status(500).json({ error: "Failed" });
  }
};

export const markParentNotificationsRead = async (req, res) => {
  const { parentId } = req.params;
  try {
    await sql`
      UPDATE "Notification" SET isread = TRUE
      WHERE parentid = ${parentId} 
      AND type IN ('MONEY_REQUEST', 'REWARD_REDEEMED', 'CHORE_COMPLETED') -- ✅
    `;
    res.sendStatus(200);
  } catch (err) {
    res.status(500).json({ error: "Failed to update parent notifications" });
  }
};

// === CHILD NOTIFICATIONS ===
export const getChildNotifications = async (req, res) => {
  const { childId } = req.params;
  try {
    const rows = await sql`
      SELECT 
        n.notificationid AS "notificationId", n.message, n.type,
        n.moneyrequestid AS "requestId", n.createdat AS "createdAt", n.isread
      FROM "Notification" n
      WHERE n.childid = ${childId}
        AND n.type IN (
          'REQUEST_APPROVED', 'REQUEST_DECLINED', 'MONEY_TRANSFER',
          'CHORE_ASSIGNED', 'CHORE_APPROVED', 'CHORE_REJECTED' -- ✅ تنبيهات المهام
        )
      ORDER BY n.createdat DESC
    `;
    return res.status(200).json(rows);
  } catch (err) {
    return res.status(500).json({ error: "Failed to load notifications" });
  }
};

export const getUnreadCountChild = async (req, res) => {
  const { childId } = req.params;
  try {
    const row = await sql`
      SELECT COUNT(*) AS unread FROM "Notification"
      WHERE childid = ${childId} AND isread = FALSE
        AND type IN (
          'REQUEST_APPROVED', 'REQUEST_DECLINED', 'MONEY_TRANSFER',
          'CHORE_ASSIGNED', 'CHORE_APPROVED', 'CHORE_REJECTED' -- ✅
        )
    `;
    res.status(200).json({ unread: Number(row[0].unread) });
  } catch (err) {
    res.status(500).json({ error: "Failed" });
  }
};

export const markChildNotificationsRead = async (req, res) => {
  const { childId } = req.params;
  try {
    await sql`UPDATE "Notification" SET isread = TRUE WHERE childid = ${childId}`;
    res.sendStatus(200);
  } catch (err) {
    res.status(500).json({ error: "Failed to update notifications" });
  }
};

export const markSingleNotificationRead = async (req, res) => {
  const { notificationId } = req.params;

  try {
    await sql`
      UPDATE "Notification"
      SET isread = TRUE
      WHERE notificationid = ${notificationId}
    `;

    res.sendStatus(200);
  } catch (err) {
    console.error("❌ Error marking single notification as read:", err);
    res.status(500).json({ error: "Failed to update notification" });
  }
};
// === CREATE NOTIFICATION ===
export const createNotification = async (parentId, childId, type, message, moneyRequestId = null, choreId = null) => {
  try {
    await sql`
      INSERT INTO "Notification" ("parentid", "childid", "type", "message", "moneyrequestid", "isread", "createdat")
      VALUES (${parentId}, ${childId}, ${type}, ${message}, ${moneyRequestId}, FALSE, CURRENT_TIMESTAMP)
    `;
  } catch (err) {
    console.error("❌ Failed to create notification:", err);
  }
};
export const saveDeviceToken = async (req, res) => {
  try {
    const { parentId, childId, fcmToken } = req.body;

    if (!fcmToken) {
      return res.status(400).json({ error: "Missing fcmToken" });
    }

    await sql`
      INSERT INTO "DeviceToken" ("parentid", "childid", "fcmtoken")
      VALUES (${parentId ?? null}, ${childId ?? null}, ${fcmToken})
      ON CONFLICT ("fcmtoken")
      DO UPDATE SET
        "parentid" = EXCLUDED."parentid",
        "childid" = EXCLUDED."childid"
    `;

    return res.status(200).json({ message: "Device token saved successfully" });
  } catch (err) {
    console.error("❌ saveDeviceToken error:", err);
    return res.status(500).json({ error: "Failed to save device token" });
  }
};