import { Router } from "express";
import {
  setupChildWallet,
  listChildGoals,
  createGoal,
  getGoalById,
  updateGoal,
  addMoneyToGoal,
  moveMoneyFromGoal,
  deleteGoal
} from "../controllers/goalController.js";

const router = Router();

router.post("/children/:childId/wallet/setup", setupChildWallet);
router.get("/children/:childId/goals", listChildGoals);

router.post("/goals", createGoal);
router.get("/goals/:goalId", getGoalById);
router.put("/goals/:goalId", updateGoal);
router.delete("/goals/:goalId", deleteGoal);

router.post("/goals/:goalId/move-in", addMoneyToGoal);
router.post("/goals/:goalId/move-out", moveMoneyFromGoal);

export default router;
