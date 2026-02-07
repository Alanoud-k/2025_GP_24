import express from "express";
import {
  getParentChores,
  getChildChores,
  // createChore,
  // updateChoreStatus,
} from "../controllers/choreController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

// Child chores
router.get("/child/:childId", protect, getChildChores);

// Parent chores
router.get("/parent/:parentId", protect, getParentChores);

// Create / Update (disabled until controller is ready)
// router.post("/create", protect, createChore);
// router.patch("/:id/status", protect, updateChoreStatus);

export default router;
