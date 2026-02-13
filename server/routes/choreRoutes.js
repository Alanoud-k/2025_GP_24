import express from "express";
import multer from "multer";
import { CloudinaryStorage } from "multer-storage-cloudinary"; 
import cloudinary from "../cloudinary.js"; 
import { 
  getParentChores, 
  getChildChores, 
  createChore, 
  updateChoreStatus,
  updateChoreDetails,
  completeChore 
} from "../controllers/choreController.js";
import { protect } from "../middleware/authMiddleware.js"; 

const router = express.Router();

// ✅ إعداد التخزين على Cloudinary
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'hassalah_proofs', // اسم المجلد في Cloudinary
    allowed_formats: ['jpg', 'png', 'jpeg'],
  },
});

const upload = multer({ storage: storage });

// --- Routes ---

router.get("/child/:childId", protect, getChildChores);

// Parent chores
router.get("/parent/:parentId", protect, getParentChores);
router.post("/create", protect, createChore);
router.patch("/:id/status", protect, updateChoreStatus);
router.put("/:id/details", protect, updateChoreDetails);

// 👇 مسار إنهاء المهمة مع رفع الصورة (اسم الحقل 'proof')
router.patch("/:id/complete", protect, upload.single('proof'), completeChore);

export default router;