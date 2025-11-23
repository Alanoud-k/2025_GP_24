import express from "express";
import { addMoney } from "../controllers/addMoneyController.js";

const router = express.Router();

// Debug route to confirm mount works
router.get("/add-money-test", (req, res) => {
  console.log("add-money-test hit");
  res.json({ ok: true });
});

// Add money route (must hit addMoneyController)
router.post("/add-money", (req, res, next) => {
  console.log("add-money route hit");
  next();
}, addMoney);

export default router;
