require("dotenv").config({ path: "./server/.env" });
const { neon } = require("@neondatabase/serverless");

const sql = neon(process.env.DATABASE_URL);

module.exports = { sql };
