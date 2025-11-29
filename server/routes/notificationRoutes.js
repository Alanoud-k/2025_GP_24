import express from "express";
import {
  getParentNotifications,
  getChildNotifications,
  getUnreadCountParent,
  getUnreadCountChild,
  markNotificationRead
} from "../controllers/notificationController.js";

const router = express.Router();

router.get("/parent/:parentId", getParentNotifications);
router.get("/child/:childId", getChildNotifications);

router.get("/unread/parent/:parentId", getUnreadCountParent);
router.get("/unread/child/:childId", getUnreadCountChild);

router.post("/mark-read", markNotificationRead);

export default router;
