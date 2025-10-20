require("dotenv").config({ path: "./server/.env" });
console.log("Database URL:", process.env.DATABASE_URL);

const express = require("express");
const cors = require("cors");
const { neon } = require("@neondatabase/serverless");

const app = express();
const sql = neon(process.env.DATABASE_URL);

app.use(cors());
app.use(express.json());

//test DB connection
app.get("/", async (req, res) => {
  try {
    console.log("Testing Neon connection...");
    const result = await sql`SELECT version()`;
    res.json({ message: "Connected to Neon", version: result[0].version });
  } catch (err) {
    console.error("❌ Neon connection error:", err);
    res.status(500).json({ error: err.message });
  }
});


app.post("/api/auth/check-user", async (req, res) => {
  const { phoneNo } = req.body;

  try {
    const users = await sql`SELECT * FROM "User" WHERE phoneNo = ${phoneNo}`;
    if (users.length > 0) {
      res.json({ exists: true, role: users[0].role });
    } else {
      res.json({ exists: false });
    }
  } catch (err) {
    console.error("❌ Error checking user:", err);
    res.status(500).json({ error: "Error checking user" });
  }
});



/*
// check if user exists by phone number
app.post("/api/auth/check-user", async (req, res) => {
  const { phoneNo } = req.body;
  try {
    const users = await sql`SELECT * FROM "User" WHERE phoneNo = ${phoneNo}`;
    if (users.length > 0) {
      res.json({ exists: true, role: users[0].role });
    } else {
      res.json({ exists: false });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Error checking user" });
  }
});
*/
/*
// register new user 
app.post("/api/auth/register", async (req, res) => {
  const { nationalId, phoneNo, firstName, lastName, dob, role } = req.body;
  try {
    const national = await sql`SELECT * FROM "National_Id" WHERE nationalId = ${nationalId} AND phoneNo = ${phoneNo} AND valid = true`;

    if (national.length === 0)
      return res.status(400).json({ message: "Invalid National ID" });

    await sql`
      INSERT INTO "User" (nationalId, phoneNo, firstName, lastName, "DoB", role)
      VALUES (${nationalId}, ${phoneNo}, ${firstName}, ${lastName}, ${dob}, ${role})
    `;

    res.json({ message: "User registered successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Registration failed" });
  }
});


// login parent
app.post("/api/auth/login-parent", async (req, res) => {
  const { phoneNo, password } = req.body;
  try {
    const result = await sql`
      SELECT u.userId, p.password
      FROM "User" u
      JOIN "Parent" p ON u.userId = p.parentId
      WHERE u.phoneNo = ${phoneNo}
    `;
    if (result.length === 0) return res.status(404).json({ message: "User not found" });
    if (result[0].password !== password) return res.status(401).json({ message: "Incorrect password" });
    res.json({ message: "Parent login successful" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Login failed" });
  }
});


// login child
app.post("/api/auth/login-child", async (req, res) => {
  const { phoneNo, pin } = req.body;
  try {
    const result = await sql`
      SELECT u.userId, c."PIN"
      FROM "User" u
      JOIN "Child" c ON u.userId = c.childId
      WHERE u.phoneNo = ${phoneNo}
    `;
    if (result.length === 0) return res.status(404).json({ message: "User not found" });
    if (result[0].PIN !== pin) return res.status(401).json({ message: "Incorrect PIN" });
    res.json({ message: "Child login successful" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Login failed" });
  }
}); */

/*http.createServer(requestHandler).listen(3000, () => {
  console.log("✅ Server running at http://localhost:3000");
});*/
app.listen(3000, () => console.log("✅ Server running on http://localhost:3000"));

