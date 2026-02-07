// server/routes/qrRoutes.js
import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  createQrRequest,
  resolveQrToken,
  confirmQrPayment,
} from "../controllers/qrPaymentController.js";

const router = express.Router();

// Demo merchant QR creation (for emulator testing)
router.post("/create", protect, createQrRequest);

// Child scans image -> resolve token to show merchant + amount
router.get("/resolve", protect, resolveQrToken);

// Child confirms -> finalize transaction + update balances
router.post("/confirm", protect, confirmQrPayment);

export default router;