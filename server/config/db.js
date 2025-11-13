// server/config/db.js

import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";
import { neon } from "@neondatabase/serverless";

// Fix __dirname for ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load .env from /server/.env
dotenv.config({
  path: path.join(__dirname, "..", ".env"),
});

// Debug (optional): print loaded env
console.log("🔧 Loaded DATABASE_URL:", process.env.DATABASE_URL ? "FOUND" : "NOT FOUND");

// Check DATABASE_URL exists
if (!process.env.DATABASE_URL) {
  throw new Error("❌ DATABASE_URL not found in server/.env");
}

// Initialize Neon client
export const sql = neon(process.env.DATABASE_URL);
