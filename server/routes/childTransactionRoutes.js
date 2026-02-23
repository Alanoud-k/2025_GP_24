import { Router } from "express";
import { getChildTransactions } from "../controllers/childTransactionController.js";

const router = Router();

// GET /api/transactions/child/:childId
router.get("/child/:childId", getChildTransactions);

export default router;