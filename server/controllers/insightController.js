import { getChildInsights, getChildChartData, getParentChartData, getGoalInsights } from '../services/insightService.js';

// 1. (الرسائل الذكية)
export async function getInsights(req, res) {
    try {
        const childId = req.params.childId;
        const insights = await getChildInsights(childId);
        res.status(200).json(insights);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch insights" });
    }
}

// 2. (الرسم البياني للطفل)
export async function getChildChart(req, res) {
    try {
        const childId = req.params.childId;
        const month = req.query.month ? Number(req.query.month) : new Date().getMonth() + 1;
        const year = req.query.year ? Number(req.query.year) : new Date().getFullYear();
        const period = req.query.period || 'month'; // week, month, year

        const chartData = await getChildChartData(childId, month, year, period);
        res.status(200).json(chartData);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch child chart data" });
    }
}

// 3. (الرسم البياني للأب)
export async function getParentChart(req, res) {
    try {
        const parentId = req.params.parentId;
        const month = req.query.month ? Number(req.query.month) : new Date().getMonth() + 1;
        const year = req.query.year ? Number(req.query.year) : new Date().getFullYear();
        const childName = req.query.childName; 
        const period = req.query.period || 'month'; // week, month, year

        const chartData = await getParentChartData(parentId, month, year, childName, period);
        res.status(200).json(chartData);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch parent chart data" });
    }
}

export async function getGoalsInsights(req, res) {
    try {
        const childId = req.params.childId;
        const insights = await getGoalInsights(childId);
        res.status(200).json(insights);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Failed to fetch goal insights" });
    }
}