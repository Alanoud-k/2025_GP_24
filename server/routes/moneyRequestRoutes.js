import express from "express";
import { 
  requestMoney, 
  getRequestsByChild,
  updateRequestStatus   
} from "../controllers/moneyRequestController.js";

const router = express.Router();

// Child sends a request (POST)
router.post("/request-money", requestMoney);

// Parent gets all money requests for a child (GET)
router.get("/money-requests/:childId", getRequestsByChild);

// Parent approves or declines a request
router.post("/money-requests/update", updateRequestStatus);

export default router;
