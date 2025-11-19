// server/routes/paymentRoutes.js (ESM)

import express from "express";
import { addMoneyToParentWallet } from "../controllers/addMoneyController.js";
import * as moyasarWebhookController from "../controllers/moyasarWebhookController.js";

const router = express.Router();

// Add money to parent wallet using saved card
router.post("/parent/:parentId/add-money", addMoneyToParentWallet);
// Moyasar webhook 
router.post("/moyasar-webhook", moyasarWebhookController.handleMoyasarWebhook);

export default router;
