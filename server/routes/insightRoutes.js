const express = require('express');
const router = express.Router();
const insightController = require('../controllers/insightController');

router.get('/:childId', insightController.getInsights);

module.exports = router;