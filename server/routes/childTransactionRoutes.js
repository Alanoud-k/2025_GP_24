import express from "express";
import { getChildTransactions } from "../controllers/childTransactionController.js";

const router = express.Router();


router.get("/child/:childId", getChildTransactions);

export default router;