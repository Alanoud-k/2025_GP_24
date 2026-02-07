import express from "express";
import { 
  getParentChores, 
  getChildChores, 
  createChore, 
  updateChoreStatus 
} from "../controllers/choreController.js";
import { protect } from "../middleware/authMiddleware.js"; 

const router = express.Router();

// ✅ هذا هو السطر المسؤول عن حل مشكلة 404
// يجب أن يكون المسار "/child/:childId" ليطابق طلب التطبيق
router.get("/child/:childId", protect, getChildChores);

// باقي المسارات
router.get("/parent/:parentId", protect, getParentChores);
router.post("/create", protect, createChore);
router.patch("/:id/status", protect, updateChoreStatus);

export default router;