// server/routes/allowanceRoutes.js (ESM)
import express from "express";
import {
  getAllowanceByChild,
  upsertAllowanceByChild,
} from "../controllers/allowanceController.js";

const router = express.Router();

router.get("/:childId", getAllowanceByChild);
router.put("/:childId", upsertAllowanceByChild);

export default router;
