import express from "express";
import { simulateCardPayment } from "../controllers/simulatePaymentController.js";

const router = express.Router();

router.post("/card/simulate", simulateCardPayment);

export default router;
