import { Router } from "express";
import { categorize } from "../controllers/categorizeController.js";

const router = Router();

router.post("/categorize", categorize);

export default router;
