import express from "express";
import { getParentTransactions } from "../controllers/parentTransactionController.js";

const router = express.Router();

router.get("/:parentId/transactions", getParentTransactions);

export default router;
