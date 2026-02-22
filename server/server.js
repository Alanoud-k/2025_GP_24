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
import paymentRoutes from "./routes/paymentRoutes.js";
import allowanceRoutes from "./routes/allowanceRoutes.js";
import childRoutes from "./routes/childRoutes.js";
import categorizeRoutes from "./routes/categorizeRoutes.js";



//import transactionRoutes from "./routes/transactionRoutes.js";
import childTransactionRoutes from "./routes/childTransactionRoutes.js";
import notificationRoutes from "./routes/notificationRoutes.js";
import parentTransactionRoutes from "./routes/parentTransactionRoutes.js";
import choreRoutes from "./routes/choreRoutes.js"; // 👈 استدعاء الملف
// PAYMENT
import { createPayment } from "./controllers/createPaymentController.js";
import { handleMoyasarWebhook } from "./controllers/moyasarWebhookController.js";
import qrRoutes from "./routes/qrRoutes.js";


import { startWeeklyAllowanceCron } from "./cron/weeklyAllowanceCron.js";
import { startChoreCron } from "./cron/choreCron.js";

// ENV SETUP
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.join(__dirname, ".env") });

const app = express();

// CORS
app.use(cors());

/* ---------------------------------------------------------
   1) MOYASAR WEBHOOK — BEFORE express.json()
--------------------------------------------------------- */
app.post(
  "/api/moyasar-webhook",
  express.raw({ type: "*/*" }),
  (req, res, next) => {
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
   2) NORMAL JSON HANDLING
--------------------------------------------------------- */
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

/* ---------------------------------------------------------
   STATIC UPLOADS
--------------------------------------------------------- */
app.use("/uploads", express.static("uploads"));

/* ---------------------------------------------------------
   REQUEST LOGGER
--------------------------------------------------------- */
app.use((req, _res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

/* ---------------------------------------------------------
   API ROUTES
--------------------------------------------------------- */
app.use("/api/auth", authRoutes);
//app.use("/api", parentRoutes);
app.use("/api", goalRoutes);
app.use("/api", moneyRequestRoutes);
app.use("/api/payment", paymentRoutes);
app.use("/api/child", childRoutes);
//app.use("/api/transaction", transactionRoutes);
app.use("/api/child", childTransactionRoutes);
app.use("/api/notifications", notificationRoutes);
//app.use("/api/parent", parentTransactionRoutes);
app.use("/api/parent", parentTransactionRoutes);
app.use("/api", parentRoutes);
app.use('/api/chores', choreRoutes);
app.use("/api/allowance", allowanceRoutes);
app.use("/api", categorizeRoutes);



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
        <meta name="viewport"
          content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">

        <style>
          html, body {
            width: 100%;
            height: 100%;
            margin: 0;
            padding: 0;
            overflow-x: hidden;
            -webkit-text-size-adjust: 100%;
          }

          body {
            background: linear-gradient(#F7FAFC, #E6F4F3);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            font-family: 'Segoe UI', sans-serif;
            color: #1A3C40;
          }

          .card {
            background: white;
            padding: 60px 35px;
            border-radius: 26px;
            box-shadow: 0 4px 14px rgba(0,0,0,0.12);
            text-align: center;
            width: 90%;
            max-width: 380px;
          }

          .check {
            font-size: 90px;
            color: #37C4BE;
            margin-bottom: 20px;
          }

          .title {
            font-size: 26px;
            font-weight: bold;
            margin-bottom: 12px;
          }

          .msg {
            font-size: 17px;
            line-height: 1.5;
            color: #555;
          }
        </style>
      </head>

      <body>
        <div class="card">
          <div class="check">✔</div>
          <div class="title">Payment Successful</div>
          <div class="msg">
            Your payment was completed successfully.<br>
            You can safely close this page.
          </div>
        </div>

        <script>
          setTimeout(() => window.close(), 3000);
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


app.use("/api/qr", qrRoutes);


// const PORT = process.env.PORT || 3000;
// //app.listen(PORT, () => {
//   //console.log(`Server running on http://localhost:${PORT}`);
//   //startWeeklyAllowanceCron();
// //});


// app.listen(PORT, () => {
//   console.log(`Server running on http://localhost:${PORT}`);
//   startWeeklyAllowanceCron();
//   startChoreCron(); 
// });

const PORT = process.env.PORT || 3000;

console.log("✅ Reached before listen");

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  
  startWeeklyAllowanceCron();
  
  if (typeof startChoreCron === 'function') {
      startChoreCron();
  }
});
////////////////////////////

