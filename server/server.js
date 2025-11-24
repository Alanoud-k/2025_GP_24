// server/server.js (ESM)

import express from "express";
import cors from "cors";
import path from "path";
import dotenv from "dotenv";
import { fileURLToPath } from "url";

// ROUTES
import authRoutes from "./routes/authRoutes.js";
import parentRoutes from "./routes/parentRoutes.js";
import goalRoutes from "./routes/goalRoutes.js";
import moneyRequestRoutes from "./routes/moneyRequestRoutes.js";

// PAYMENT CONTROLLERS
import { createPayment } from "./controllers/createPaymentController.js";
import { handleMoyasarWebhook } from "./controllers/moyasarWebhookController.js";

// ENV AND SETUP
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.join(__dirname, ".env") });

if (!process.env.DATABASE_URL) {
  console.error("DATABASE_URL is missing in .env");
  process.exit(1);
}

const app = express();

// CORS and JSON for all normal routes
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Simple request logger
app.use((req, _res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

/* -----------------------------------------
   NORMAL API ROUTES
------------------------------------------ */

app.use("/api/auth", authRoutes);
app.use("/api", parentRoutes);
app.use("/api", goalRoutes);
app.use("/api", moneyRequestRoutes);

/* -----------------------------------------
   PAYMENT ROUTES
------------------------------------------ */

// Payment creation endpoint for Flutter
app.post("/api/create-payment/:parentId", createPayment);

// Deprecated payment endpoints (no longer used)
// import { addMoney, confirmPayment } from "./controllers/addMoneyController.js";
// app.post("/api/add-money", addMoney);
// app.post("/api/confirm-payment", confirmPayment);

/* -----------------------------------------
   MOYASAR WEBHOOK ROUTE
   Must use express.raw and be placed after JSON middleware
------------------------------------------ */

app.post(
  "/api/moyasar-webhook",
  express.raw({ type: "application/json" }),

  (req, res, next) => {
    req.rawBody = req.body;

    try {
      req.body = JSON.parse(req.body.toString("utf8"));
    } catch (e) {
      console.error("Invalid JSON in webhook");
      return res.sendStatus(400);
    }

    next();
  },

  handleMoyasarWebhook
);

/* -----------------------------------------
   PAYMENT REDIRECT ROUTES
------------------------------------------ */

app.get("/payment-success", (_req, res) => {
  res.send("Payment completed successfully.");
});

app.get("/payment-failed", (_req, res) => {
  res.send("Payment failed.");
});

/* -----------------------------------------
   HEALTH CHECK
------------------------------------------ */

app.get("/", (_req, res) => {
  res.send("Hassalah API is running.");
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
