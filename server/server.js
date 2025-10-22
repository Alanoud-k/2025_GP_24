require("dotenv").config({ path: "./server/.env" });
const express = require("express");
const cors = require("cors");
const authRoutes = require("./routes/authRoutes");

const app = express();
app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);

app.get("/", (req, res) => res.send("API is running..."));

app.listen(3000, () => console.log("✅ Server running at http://localhost:3000"));
