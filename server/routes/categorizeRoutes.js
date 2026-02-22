import express from "express";
import { categorize } from "../controllers/categorizeController.js";

const router = express.Router();

// POST /api/categorize
router.post("/", categorize);

export default router;