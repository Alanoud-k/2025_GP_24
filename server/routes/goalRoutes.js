import { Router } from "express";

import {
  setupChildWallet,
  getSaveBalance,
  listChildGoals,
  createGoal,
  contributeToGoal,
  moveIn,
  moveOut,
  getChildWalletBalances,
  addMoneyToGoal,
  moveMoneyFromGoal
} from "../controllers/goalController.js";

const router = Router();

router.post("/children/:childId/wallet/setup", setupChildWallet);
router.get("/children/:childId/save-balance", getSaveBalance);
router.get("/children/:childId/goals", listChildGoals);
router.post("/goals", createGoal);
router.post("/goals/:goalId/contributions", contributeToGoal);

router.post("/saving/move-in", moveIn);
router.post("/saving/move-out", moveOut);

router.get("/children/:childId/wallet/balances", getChildWalletBalances);

router.post("/goals/:goalId/move-in", addMoneyToGoal);
router.post("/goals/:goalId/move-out", moveMoneyFromGoal);

export default router;
