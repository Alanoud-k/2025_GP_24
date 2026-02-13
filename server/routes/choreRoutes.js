import express from "express";
import { 
  getParentChores, 
  getChildChores, 
  createChore, 
  completeChore,
  updateChoreStatus,
  updateChoreDetails // 👈 1. استيراد الدالة الجديدة
  
} from "../controllers/choreController.js";
import { protect } from "../middleware/authMiddleware.js"; 
import multer from "multer"; // pic
import { CloudinaryStorage } from "multer-storage-cloudinary"; //pic
import cloudinary from "../cloudinary.js"; // pic
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

// إعداد التخزين
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'hassalah_proofs',
    allowed_formats: ['jpg', 'png', 'jpeg'],
  },
});

const upload = multer({ storage: storage });

//const router = express.Router();

router.get("/child/:childId", protect, getChildChores);

// Parent chores
router.get("/parent/:parentId", protect, getParentChores);
router.post("/create", protect, createChore);
router.patch("/:id/status", protect, updateChoreStatus);

// 👇 2. إضافة مسار التعديل
router.put("/:id/details", protect, updateChoreDetails);

router.patch("/:id/complete", protect, completeChore);

router.patch("/:id/complete", protect, upload.single('proof'), completeChore);

export default router;
