const insightService = require('../services/insightService');

async function getInsights(req, res) {
    try {
        const childId = req.params.childId;

        const insights = await insightService.getChildInsights(childId);

        res.status(200).json(insights);

    } catch (error) {
        res.status(500).json({ error: "Failed to fetch insights" });
    }
}

module.exports = {
    getInsights
};