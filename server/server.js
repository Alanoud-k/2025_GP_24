require("dotenv").config();
const http = require("http");
const { neon } = require("@neondatabase/serverless");

const sql = neon(process.env.DATABASE_URL);

const requestHandler = async (req, res) => {
  try {
    const result = await sql`SELECT version()`;
    const { version } = result[0];
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end(`Connected to Neon! PostgreSQL version: ${version}`);
  } catch (error) {
    console.error(error);
    res.writeHead(500, { "Content-Type": "text/plain" });
    res.end("Database connection failed");
  }
};

http.createServer(requestHandler).listen(3000, () => {
  console.log("✅ Server running at http://localhost:3000");
});
