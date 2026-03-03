import express from 'express';
import { getInsights } from '../controllers/insightController.js';

const router = express.Router();

router.get('/:childId', getInsights);

export default router;