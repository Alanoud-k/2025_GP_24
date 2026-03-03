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