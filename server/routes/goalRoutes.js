// server/routes/goalRoutes.js
import { Router } from 'express';
import {
  setupChildWallet,
  getSaveBalance,
  listChildGoals,
  createGoal,
  contributeToGoal,
} from '../controllers/goalController.js';
import { moveIn, moveOut } from '../controllers/goalController.js';
import { getChildWalletBalances } from '../controllers/goalController.js';

const router = Router();

//  /api/children/:childId/wallet/setup
router.post('/children/:childId/wallet/setup', setupChildWallet);

//  /api/children/:childId/save-balance
router.get('/children/:childId/save-balance', getSaveBalance);

//  /api/children/:childId/goals
router.get('/children/:childId/goals', listChildGoals);

//  /api/goals
router.post('/goals', createGoal);

//  /api/goals/:goalId/contributions
router.post('/goals/:goalId/contributions', contributeToGoal);

router.post('/saving/move-in', moveIn);
router.post('/saving/move-out', moveOut);
router.get('/children/:childId/wallet/balances', getChildWalletBalances);
router.post("/goals/:goalId/move-in", addMoneyToGoal);
router.post("/goals/:goalId/move-out", moveMoneyFromGoal);

export default router;
