import express from 'express';
import { getInsights } from '../controllers/insightController.js';

const router = express.Router();

router.get('/:childId', getInsights);

router.get('/child-chart/:childId', getChildChart);
router.get('/parent-chart/:parentId', getParentChart);

export default router;