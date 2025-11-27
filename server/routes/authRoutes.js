// server/routes/authRoutes.js  (ESM)

import express from "express";
//import { uploadAvatar } from "../middleware/uploadAvatar.js";

import {
  checkUser,
  registerParent,
  getNameByPhone,
  loginParent,
  loginChild,
  logout,
  getParentInfo,
  getParentById,
  verifySecurityAnswer,
  resetPassword,
} from "../controllers/authController.js";

import {
  getChildrenByParent,
  registerChild,
  getChildInfo,
  //updateChildAvatar,   // <-- Only declared ONCE
} from "../controllers/childController.js";

import { transferMoney } from "../controllers/transferController.js";
import { protect } from "../middleware/authMiddleware.js";
import { updateChildLimit } from "../controllers/authController.js";
import { changeParentPassword, changeChildPassword } from "../controllers/parentController.js";

const router = express.Router();

// ---------- Auth & user ----------
router.post("/check-user", checkUser);
router.post("/register-parent", registerParent);
router.get("/name/:phoneNo", getNameByPhone);
router.post("/login-parent", loginParent);
router.post("/login-child", loginChild);
router.post("/verify-security-answer", verifySecurityAnswer);
router.post("/reset-password", resetPassword);
router.post("/logout", logout);
router.put("/parent/:parentId/password", protect, changeParentPassword);
router.put("/child/:childId/password", protect, changeChildPassword);
// ---------- Parent / Child ----------
router.get("/parent/:parentId", protect, getParentInfo);
router.get("/parent-basic/:parentId", protect, getParentById);
router.get("/child/info/:childId", protect, getChildInfo);
router.get("/parent/:parentId/children", protect, getChildrenByParent);

router.post("/child/register", registerChild);
router.put("/child/update-limit/:childId", protect, updateChildLimit);

// ---------- Transfer ----------
router.post("/transfer", protect, transferMoney);

// ---------- Avatar Upload ----------
//router.post(
  //"/child/upload-avatar/:childId",
  //protect,
  //uploadAvatar.single("avatar"),
  //updateChildAvatar
//);

export default router;
