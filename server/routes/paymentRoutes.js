const express = require("express");
const router = express.Router();

const { createPayment } = require("../controllers/addMoneyController");
const { handleMoyasarWebhook } = require("../controllers/moyasarWebhookController");

// Payment creation
router.post("/create-payment", createPayment);

// Moyasar webhook
router.post("/moyasar-webhook", handleMoyasarWebhook);

module.exports = router;
