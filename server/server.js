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
import transactionRoutes from "./routes/transactionRoutes.js";

// PAYMENT
import { createPayment } from "./controllers/createPaymentController.js";
import { handleMoyasarWebhook } from "./controllers/moyasarWebhookController.js";

// ENV SETUP
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.join(__dirname, ".env") });

const app = express();

// CORS for all normal endpoints
app.use(cors());

/* ---------------------------------------------------------
   1) MOYASAR WEBHOOK — MUST COME BEFORE express.json()
--------------------------------------------------------- */

app.post(
  "/api/moyasar-webhook",
  // Keep raw body so signature check works even if JSON is invalid
  express.raw({ type: "*/*" }),
  (req, res, next) => {
    // Debug logging so we see what Moyasar actually sends
    console.log("Webhook hit /api/moyasar-webhook");
    console.log("Headers:", req.headers);

    req.rawBody = req.body;

    try {
      const asString = req.body.toString("utf8");
      console.log("Raw webhook body:", asString);
      req.body = JSON.parse(asString || "{}");
    } catch (err) {
      console.error("Invalid JSON in webhook:", err.message);
      return res.sendStatus(400);
    }

    next();
  },
  handleMoyasarWebhook
);

/* ---------------------------------------------------------
   2) NORMAL EXPRESS JSON HANDLING — AFTER WEBHOOK
--------------------------------------------------------- */

app.use(express.json());
/* ---------------------------------------------------------
   UPLOAD PICTURE
--------------------------------------------------------- */
app.use("/uploads", express.static("uploads"));

app.use(express.urlencoded({ extended: true }));

// Request logger for all other routes
app.use((req, _res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

/* ---------------------------------------------------------
   OTHER ROUTES
--------------------------------------------------------- */

app.use("/api/auth", authRoutes);
app.use("/api", parentRoutes);
app.use("/api", goalRoutes);
app.use("/api", moneyRequestRoutes);
app.use("/api/transaction", transactionRoutes);


// Create payment
app.post("/api/create-payment/:parentId", createPayment);

/* ---------------------------------------------------------
   REDIRECT PAGES
--------------------------------------------------------- */

app.get("/payment-success", (_req, res) => {
  res.send(`
    <html>
      <head>
        <title>Payment Successful</title>
        <style>
          body {
            background: #F7F8FA;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            font-family: 'Segoe UI', Tahoma, sans-serif;
            color: #333;
          }
          .card {
            background: white;
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 350px;
            width: 90%;
          }
          .check {
            font-size: 60px;
            color: #37C4BE;
            margin-bottom: 10px;
          }
          .title {
            font-size: 22px;
            font-weight: bold;
            color: #2C3E50;
            margin-bottom: 6px;
          }
          .msg {
            font-size: 14px;
            color: #666;
            margin-bottom: 20px;
          }
          .closing {
            font-size: 12px;
            color: #999;
          }
        </style>
      </head>

      <body>
        <div class="card">
          <div class="check">✔</div>
          <div class="title">Payment Successful</div>
          <div class="msg">Your payment has been processed successfully.</div>
          <div class="closing">This window will close automatically…</div>
        </div>

        <script>
          setTimeout(() => {
            window.close();
          }, 3000); // 3 seconds
        </script>
      </body>
    </html>
  `);
});


app.get("/payment-failed", (_req, res) => {
  res.send("Payment failed.");
});

/* ---------------------------------------------------------
   HEALTH CHECK
--------------------------------------------------------- */

app.get("/", (_req, res) => {
  res.send("Hassalah API is running.");
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});


