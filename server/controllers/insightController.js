// استيراد واحد يجمع كل الدوال
import { getChildInsights, getChildChartData, getParentChartData } from '../services/insightService.js';

// 1.   (الرسائل الذكية)
export async function getInsights(req, res) {
    try {
        const childId = req.params.childId;
        const insights = await getChildInsights(childId);
        res.status(200).json(insights);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch insights" });
    }
}

// 2.   (الرسم البياني للطفل)
export async function getChildChart(req, res) {
    try {
        const chartData = await getChildChartData(req.params.childId);
        res.status(200).json(chartData);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch child chart data" });
    }
}

// 3.   (الرسم البياني للأب)
export async function getParentChart(req, res) {
    try {
        const chartData = await getParentChartData(req.params.parentId);
        res.status(200).json(chartData);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch parent chart data" });
    }
}