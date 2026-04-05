import express from 'express';
import { getInsights, getChildChart, getParentChart,   getGoalsInsights, getParentInsightsController  
 } from '../controllers/insightController.js';

const router = express.Router();

router.get('/parent/:parentId', getParentInsightsController);

// المسارات الجديدة للرسوم البيانية
router.get('/child-chart/:childId', getChildChart);
router.get('/parent-chart/:parentId', getParentChart);

// المسار القديم الخاص بالرسائل الذكية

router.get('/goals/:childId', getGoalsInsights);

router.get('/:childId', getInsights);


export default router;