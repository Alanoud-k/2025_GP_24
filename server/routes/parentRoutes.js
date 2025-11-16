import express from "express";
import * as parentController from "../controllers/parentController.js";

const router = express.Router();

// ✅ Define routes
router.get("/parent/:parentId", parentController.getParentInfo);
router.get("/parent/:parentId/children", parentController.getChildrenByParent);
router.put("/parent/:parentId/password", parentController.changeParentPassword);
router.put("/child/:childId/password", parentController.changeChildPassword);

export default router;