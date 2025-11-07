// =============================
//  server.js — Hassalah Backend
// =============================

// تحميل المتغيرات من ملف .env
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, ".env") });

// استدعاء المكتبات
const express = require("express");
const cors = require("cors");
const authRoutes = require("./routes/authRoutes");
const parentRoutes = require("./routes/parentRoutes");


// إنشاء التطبيق
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

//  تأكد أن متغير قاعدة البيانات موجود
if (!process.env.DATABASE_URL) {
  console.error(" DATABASE_URL is missing in .env file!");
  process.exit(1);
}

// ربط الراوتر
app.use("/api/auth", authRoutes);
app.use("/api", parentRoutes);


// اختبار سريع (للتأكد أن السيرفر شغال)
app.get("/", (req, res) => {
  res.send("✅ API is running successfully.");
});

// تشغيل السيرفر
const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(` Server running at http://localhost:${PORT}`);
});
