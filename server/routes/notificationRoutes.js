import express from "express";
import { getParentNotifications } from "../controllers/notificationController.js";

const router = express.Router();

router.get("/parent/:parentId", getParentNotifications);

export default router;
