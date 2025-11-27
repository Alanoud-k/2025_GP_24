import express from "express";
import { processTransaction } from "../controllers/transactionsController.js";

const router = express.Router();

router.post("/process", processTransaction);

export default router;
