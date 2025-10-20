// testCheckUser.js
import fetch from "node-fetch"; // if using ESM
// or const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

async function testCheckUser() {
  const response = await fetch("http://localhost:3000/api/auth/check-user", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ phoneNo: "0555555555" }),
  });

  const data = await response.json();
  console.log("Response:", data);
}

testCheckUser();
