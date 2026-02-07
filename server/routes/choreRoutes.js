import express from "express";
// 👇👇 تأكدي أن هذا السطر يحتوي على createChore و updateChoreStatus
import { 
  getParentChores, 
  getChildChores, 
  createChore,       // 👈 كانت ناقصة هنا
  updateChoreStatus  // 👈 وكانت ناقصة هنا
} from "../controllers/choreController.js";

import { protect } from "../middleware/authMiddleware.js"; 

const router = express.Router();

// الآن السيرفر سيتعرف على الدوال ولن ينهار
router.get("/child/:childId", protect, getChildChores);
router.get("/parent/:parentId", protect, getParentChores);
router.post("/create", protect, createChore);
router.patch("/:id/status", protect, updateChoreStatus);

export default router;