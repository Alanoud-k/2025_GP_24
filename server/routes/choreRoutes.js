import express from "express";
import { 
  getParentChores, 
  getChildChores, 
  createChore, 
  updateChoreStatus,
  updateChoreDetails // 👈 1. استيراد الدالة الجديدة
} from "../controllers/choreController.js";
import { protect } from "../middleware/authMiddleware.js"; 

const router = express.Router();

router.get("/child/:childId", protect, getChildChores);
router.get("/parent/:parentId", protect, getParentChores);
router.post("/create", protect, createChore);
router.patch("/:id/status", protect, updateChoreStatus);

// 👇 2. إضافة مسار التعديل
router.put("/:id/details", protect, updateChoreDetails);

export default router;