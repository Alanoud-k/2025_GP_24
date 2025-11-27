// server/routes/transactionRoutes.js
import express from "express";
import { simulateCardPayment } from "../controllers/transactionController.js";

const router = express.Router();

// Simulated card payment from child card screen
router.post("/simulate-card", simulateCardPayment);

export default router;
