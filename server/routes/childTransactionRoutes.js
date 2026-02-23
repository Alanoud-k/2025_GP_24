import { Router } from "express";
import { getChildTransactions } from "../controllers/childTransactionController.js";

const router = Router();

router.get("/:childId/transactions", getChildTransactions);

export default router;