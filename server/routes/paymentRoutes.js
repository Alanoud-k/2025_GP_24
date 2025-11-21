import express from "express";
import { createPayment } from "../controllers/createPaymentController.js";
import { handleMoyasarWebhook } from "../controllers/moyasarWebhookController.js";

const router = express.Router();

router.post("/parent/:parentId/create-payment", createPayment);

// ⭐ FIX: accept BOTH GET and POST
router.post("/moyasar-webhook", handleMoyasarWebhook);
router.get("/moyasar-webhook", handleMoyasarWebhook);

export default router;
