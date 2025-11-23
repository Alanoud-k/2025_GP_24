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

// ENV + SETUP
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.join(__dirname, ".env") });

if (!process.env.DATABASE_URL) {
  console.error("DATABASE_URL is missing in .env");
  process.exit(1);
}

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Simple request logger
app.use((req, _res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

/* -----------------------------------------
   API ROUTES
------------------------------------------ */

app.use("/api/auth", authRoutes);
app.use("/api", parentRoutes);
app.use("/api", goalRoutes);
app.use("/api", moneyRequestRoutes);

// Payment creation endpoint used by Flutter
app.post("/api/create-payment/:parentId", createPayment);

/* -----------------------------------------
   MOYASAR WEBHOOK HANDLER
------------------------------------------ */

app.post(
  "/api/moyasar-webhook",
  express.raw({ type: "*/*" }),
  (req, res, next) => {
    try {
      req.body = JSON.parse(req.body.toString("utf8"));
    } catch (e) {}
    next();
  },
  handleMoyasarWebhook
);

/* -----------------------------------------
   PAYMENT REDIRECT ROUTES (for browser)
------------------------------------------ */

// Shown when Moyasar redirects after success
app.get("/payment-success", (_req, res) => {
  res.send("Payment completed successfully.");
});

// Shown when Moyasar redirects after failure
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
app.listen(PORT, () =>
  console.log(`Server running on http://localhost:${PORT}`)
);
