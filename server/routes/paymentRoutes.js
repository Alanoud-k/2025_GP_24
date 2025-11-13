// server/routes/paymentRoutes.js (ESM version)

import express from "express";
import * as addMoneyController from "../controllers/addMoneyController.js";
import * as moyasarWebhookController from "../controllers/moyasarWebhookController.js";

const router = express.Router();

// Payment creation
router.post("/create-payment", addMoneyController.createPayment);

// Moyasar webhook
router.post("/moyasar-webhook", moyasarWebhookController.handleMoyasarWebhook);

export default router;
