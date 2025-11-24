import multer from "multer";
import path from "path";
import { fileURLToPath } from "url";

// ⬇️ لتحديد مسار الملفات في ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ---------------- CONFIG STORAGE ----------------
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, "..", "uploads", "avatars"));
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    const unique = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, unique + ext);
  },
});

// ---------------- FILE FILTER ----------------
const fileFilter = (req, file, cb) => {
  console.log("Uploaded mimetype:", file.mimetype);

  // نقبل أي ملف نوعه يبدأ بـ image/
  if (file.mimetype && file.mimetype.startsWith("image/")) {
    cb(null, true);
  } else {
    cb(new Error("Only images are allowed"), false);
  }
};


// ---------------- MULTER INSTANCE ----------------
export const uploadAvatar = multer({
  storage,
  fileFilter,
  limits: { fileSize: 3 * 1024 * 1024 }, // 3 MB
});
