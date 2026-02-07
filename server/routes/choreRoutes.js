import express from "express";
import { getParentChores, getChildChores } from "../controllers/choreController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.get("/child/:childId", protect, getChildChores);
router.get("/parent/:parentId", protect, getParentChores);

export default router;
