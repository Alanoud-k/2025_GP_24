import express from "express";
import { getChildTransactions } from "../controllers/childTransactionController.js";

const router = express.Router();

router.get("/:childId/transactions", getChildTransactions);

export default router;
