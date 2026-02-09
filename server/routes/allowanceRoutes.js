// server/routes/allowanceRoutes.js (ESM)
import express from "express";
import {
  getAllowanceByChild,
  upsertAllowanceByChild,
} from "../controllers/allowanceController.js";

const router = express.Router();

import { protect } from "../middleware/authMiddleware.js";

router.get("/:childId", protect, getAllowanceByChild);
router.put("/:childId", protect, upsertAllowanceByChild);


export default router;
