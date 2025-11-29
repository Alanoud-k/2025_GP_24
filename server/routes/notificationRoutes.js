// server/routes/notificationRoutes.js (ESM)

import express from "express";
import { getParentNotifications } from "../controllers/notificationController.js";

const router = express.Router();

// GET /api/notifications/parent/:parentId
router.get("/parent/:parentId", getParentNotifications);

export default router;
