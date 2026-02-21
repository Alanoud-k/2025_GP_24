// server/routes/childRoutes.js (ESM)
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import { 
  getChildrenByParent
} from "../controllers/childController.js";
const router = express.Router();

// GET /api/child/parent/:parentId/children
router.get("/parent/:parentId/children", protect, getChildrenByParent);

export default router;
