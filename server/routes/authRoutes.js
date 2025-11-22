// server/routes/authRoutes.js  (ESM)

import express from "express";

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
} from "../controllers/childController.js";

import { transferMoney } from "../controllers/transferController.js";

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
router.get("/parent/:parentId", getParentInfo);
router.get("/parent-basic/:parentId", getParentById);
router.get("/child/info/:childId", getChildInfo);
router.get("/parent/:parentId/children", getChildrenByParent);

router.post("/child/register", registerChild);

// ---------- Transfer ----------
router.post("/transfer", transferMoney);

// ----- ESM default export -----
export default router;
