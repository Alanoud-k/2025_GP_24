import express from "express";
import multer from "multer";
import { CloudinaryStorage } from "multer-storage-cloudinary"; 
import cloudinary from "../cloudinary.js"; // تأكدي أن مسار cloudinary صحيح لديكِ

// ✅ استيراد واحد فقط يجمع كل الدوال لمنع التكرار
import { 
  getParentChores, 
  getChildChores, 
  createChore, 
  updateChoreStatus,
  updateChoreDetails,
  completeChore,
  rejectChore // 👈 دالة الرفض مضافة هنا مع البقية
} from "../controllers/choreController.js";

import { protect } from "../middleware/authMiddleware.js"; 

const router = express.Router();

// ✅ إعداد التخزين على Cloudinary
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'hassalah_proofs', 
    allowed_formats: ['jpg', 'png', 'jpeg'],
  },
});

const upload = multer({ storage: storage });

// --- Routes ---

router.get("/child/:childId", protect, getChildChores);
router.get("/parent/:parentId", protect, getParentChores);
router.post("/create", protect, createChore);
router.patch("/:id/status", protect, updateChoreStatus);
router.put("/:id/details", protect, updateChoreDetails);
router.patch("/:id/complete", protect, upload.single('proof'), completeChore);

// 👇 مسار رفض المهمة الجديد
router.patch("/:id/reject", protect, rejectChore);

export default router;