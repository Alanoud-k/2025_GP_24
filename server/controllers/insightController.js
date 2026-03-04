import { getChildInsights } from '../services/insightService.js';

export async function getInsights(req, res) {
    try {
        const childId = req.params.childId;
        const insights = await getChildInsights(childId);
        res.status(200).json(insights);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch insights" });
    }
}

// في insightController.js
import { getChildInsights, getChildChartData, getParentChartData } from '../services/insightService.js';

export async function getChildChart(req, res) {
    try {
        const chartData = await getChildChartData(req.params.childId);
        res.status(200).json(chartData);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch child chart data" });
    }
}

export async function getParentChart(req, res) {
    try {
        const chartData = await getParentChartData(req.params.parentId);
        res.status(200).json(chartData);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch parent chart data" });
    }
}