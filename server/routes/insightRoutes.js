import express from 'express';
import { getInsights, getChildChart, getParentChart,   getGoalsInsights 
 } from '../controllers/insightController.js';

const router = express.Router();

// المسارات الجديدة للرسوم البيانية
router.get('/child-chart/:childId', getChildChart);
router.get('/parent-chart/:parentId', getParentChart);

// المسار القديم الخاص بالرسائل الذكية

router.get('/goals/:childId', getGoalsInsights);

router.get('/:childId', getInsights);
export default router;