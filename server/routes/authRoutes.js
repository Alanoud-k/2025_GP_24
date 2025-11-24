// server/routes/authRoutes.js  (ESM)

import express from "express";
import { uploadAvatar } from "../middleware/uploadAvatar.js";
import { updateChildAvatar } from "../controllers/childController.js";

import {
  checkUser,
  registerParent,
  getNameByPhone,
  loginParent,
  loginChild,
  // forgotPassword,
  logout,
  getParentInfo,
  getChildInfo,
  getParentById,
  verifySecurityAnswer, 
  resetPassword
} from "../controllers/authController.js";

import {
  getChildrenByParent,
  registerChild,
  getChildInfo as getChildInfoForChild, // CHANGED: use childController version
  updateChildAvatar,
} from "../controllers/childController.js";

import { transferMoney } from "../controllers/transferController.js";
import { protect } from "../middleware/authMiddleware.js";


const router = express.Router();

// ---------- Auth & user ----------
router.post("/check-user", checkUser);          // ✅ هذا هو الراوت المطلوب
router.post("/register-parent", registerParent);
router.get("/name/:phoneNo", getNameByPhone);
router.post("/login-parent", loginParent);
router.post("/login-child", loginChild);
router.post("/verify-security-answer", verifySecurityAnswer);
router.post("/reset-password", resetPassword);

// router.post("/forgot-password", forgotPassword);
router.post("/logout", logout);

// ---------- Parent / Child info ----------
router.get("/parent/:parentId", protect, getParentInfo);
router.get("/parent-basic/:parentId", protect, getParentById);
router.get("/child/info/:childId", protect, getChildInfo);
router.get("/parent/:parentId/children", protect, getChildrenByParent);


router.post("/child/register", registerChild);

// ---------- Transfer ----------
router.post("/transfer", transferMoney);

// ------Avatar ------
router.post(
  "/child/upload-avatar/:childId",
  protect,                     // CHANGED: secure avatar upload
  uploadAvatar.single("avatar"),
  updateChildAvatar
);

// ----- ESM default export -----
export default router;



