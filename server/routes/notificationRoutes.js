// server/routes/notificationRoutes.js

import express from "express";
import {
  getParentNotifications,
  getChildNotifications,
  getUnreadCountParent,
  getUnreadCountChild,
  markChildNotificationsRead,
  markParentNotificationsRead,  
  markSingleNotificationRead    /// NEW
} from "../controllers/notificationController.js";

const router = express.Router();

router.get("/parent/:parentId", getParentNotifications);
router.get("/child/:childId", getChildNotifications);

router.get("/unread/parent/:parentId", getUnreadCountParent);
router.get("/unread/child/:childId", getUnreadCountChild);

/// NEW:
router.post("/mark-read/parent/:parentId", markParentNotificationsRead);

router.post("/mark-read/child/:childId", markChildNotificationsRead);

router.post("/mark-read/:notificationId", markSingleNotificationRead);
export default router;
