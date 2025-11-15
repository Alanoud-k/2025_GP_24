// server/server.js  (ESM)

import express from "express";
import cors from "cors";
import path from "path";
import dotenv from "dotenv";
import { fileURLToPath } from "url";

import authRoutes from "./routes/authRoutes.js";
import parentRoutes from "./routes/parentRoutes.js";
import paymentRoutes from "./routes/paymentRoutes.js";
import goalRoutes from "./routes/goalRoutes.js"; // لو ما سويته لسه احذفه من هنا
import moneyRequestRoutes from "./routes/moneyRequestRoutes.js";

// ----- ESM __dirname setup -----
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ----- Load .env from server/.env -----
dotenv.config({ path: path.join(__dirname, ".env") });

if (!process.env.DATABASE_URL) {
  console.error("❌ DATABASE_URL is missing in server/.env");
  process.exit(1);
}

// ----- Create app -----
const app = express();
app.use(cors());
app.use(express.json());

// Optional: log every request
app.use((req, _res, next) => {
  console.log(`➡️  ${req.method} ${req.url}`);
  next();
});

// ----- Mount routers -----
app.use("/api/auth", authRoutes); // ✅ هنا يكون /api/auth/...
app.use("/api", parentRoutes);
app.use("/api", paymentRoutes);
app.use("/api", goalRoutes); 
app.use("/api", moneyRequestRoutes);

// Test route
app.get("/", (_req, res) => {
  res.send("✅ API is running successfully.");
});

// ----- Start server -----
const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`✅ Server running at http://localhost:${PORT}`);
});
