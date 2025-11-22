// server/routes/paymentRoutes.js
import express from "express";
import { createPayment } from "../controllers/createPaymentController.js";
import { handleMoyasarWebhook } from "../controllers/moyasarWebhookController.js";
import { addMoney } from "../controllers/addMoneyController.js";

const router = express.Router();

// Old flow (keep if you still use it somewhere)
router.post("/parent/:parentId/create-payment", createPayment);

// New flow (no redirect)
router.post("/add-money", addMoney);

// Webhook (optional)
router.post("/moyasar-webhook", handleMoyasarWebhook);
router.get("/moyasar-webhook", handleMoyasarWebhook);

export default router;
