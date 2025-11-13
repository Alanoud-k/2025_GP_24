import express from "express";
import * as parentController from "../controllers/parentController.js";

const router = express.Router();

// ✅ Define route to get parent info by ID
router.get("/parent/:parentId", parentController.getParentInfo);

export default router;
