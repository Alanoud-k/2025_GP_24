// server/routes/goalRoutes.js
import { Router } from 'express';
import {
  setupChildWallet,
  getSaveBalance,
  listChildGoals,
  createGoal,
  contributeToGoal,
} from '../controllers/goalController.js';

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

export default router;
