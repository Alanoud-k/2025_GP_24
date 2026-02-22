// server/routes/rewardRoutes.js
import express from "express";
import {
  createReward, getParentRewards, getChildRewardsData,
  updateReward, deleteReward, redeemReward
} from "../controllers/rewardController.js";

const router = express.Router();

router.post("/create", createReward);
router.get("/parent/:parentId", getParentRewards);
router.get("/child/:childId", getChildRewardsData);
router.put("/:rewardId", updateReward);
router.delete("/:rewardId", deleteReward);
router.post("/redeem", redeemReward);

export default router;