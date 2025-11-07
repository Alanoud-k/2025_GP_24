const bcrypt = require("bcrypt");
const { sql } = require("../config/db");
const { validatePhone, validatePassword } = require("../utils/validators");

//----------------------------------------------------------------------
// CHECK USER
// --------------------------------------------------------------------
exports.checkUser = async (req, res) => {
const { phoneNo } = req.body;

if (!validatePhone(phoneNo)) {
return res.status(400).json({ error: "Invalid phone number format" });
}

try {
const parent = await sql`SELECT * FROM "Parent" WHERE phoneNo = ${phoneNo}`;
const child = await sql`SELECT * FROM "Child" WHERE phoneNo = ${phoneNo}`;

if (parent.length > 0)
return res.json({ exists: true, role: "Parent" });
if (child.length > 0)
return res.json({ exists: true, role: "Child" });

return res.json({ exists: false });
} catch (err) {
console.error("Error checking user:", err);
res.status(500).json({ error: "Error checking user" });
}
};

//----------------------------------------------------------------------
// PARENT REGISTRATION (with bcrypt hashing)
// --------------------------------------------------------------------
exports.registerParent = async (req, res) => {
const { firstName, lastName, nationalId, DoB, phoneNo, password } = req.body;

// Validate age (parent must be 18 or older)
const birthDate = new Date(DoB);
const age = new Date().getFullYear() - birthDate.getFullYear();
if (age < 18)
return res.status(400).json({ error: "Parent must be at least 18 years old" });


if (!firstName || !lastName || !nationalId || !DoB || !phoneNo || !password)
return res.status(400).json({ error: "All fields are required" });

if (!validatePhone(phoneNo))
return res.status(400).json({ error: "Invalid phone number format" });

if (!validatePassword(password))
return res.status(400).json({ error: "Weak password" });

try {
const existing = await sql`SELECT * FROM "Parent" WHERE phoneNo = ${phoneNo}`;
if (existing.length > 0)
return res.status(400).json({ error: "Phone number already registered" });

const national = await sql`
SELECT * FROM "National_Id"
WHERE nationalId = ${nationalId} AND valid = true
`;
if (national.length === 0)
return res.status(400).json({ error: "National ID not found" });

  if (national[0].valid === false) {
      return res.status(400).json({ error: "National ID already registered" });
    }

// ✅ تشفير كلمة المرور
const saltRounds = 10;
const hashedPassword = await bcrypt.hash(password, saltRounds);

// ✅ تخزين الباسوورد المشفّر
const inserted = await sql`
INSERT INTO "Parent" (nationalId, phoneNo, firstName, lastName, "DoB", password)
VALUES (${nationalId}, ${phoneNo}, ${firstName}, ${lastName}, ${DoB}, ${hashedPassword})
RETURNING parentId AS "parentId"
`;
const newParentId = inserted[0].parentId;

await sql`
INSERT INTO "Wallet" (parentId, walletBalance, currency)
VALUES (${newParentId}, 0, 'SAR')
`;

await sql`
UPDATE "National_Id"
SET valid = false
WHERE nationalId = ${nationalId}
`;

res.json({ message: "Parent registered successfully", parentId: newParentId });
} catch (err) {
console.error("Registration error:", err);
res.status(500).json({ error: "Failed to register parent" });
}
};

//----------------------------------------------------------------------
exports.getNameByPhone = async (req, res) => {
  const { phoneNo } = req.params;
  try {
    const parent = await sql`
      SELECT firstName FROM "Parent" WHERE phoneNo = ${phoneNo}
    `;
    const child = await sql`
      SELECT firstName FROM "Child" WHERE phoneNo = ${phoneNo}
    `;
    if (parent.length > 0) return res.json({ firstName: parent[0].firstname });
    if (child.length > 0) return res.json({ firstName: child[0].firstname });
    res.status(404).json({ error: "User not found" });
  } catch (err) {
    console.error("Error fetching firstName:", err);
    res.status(500).json({ error: "Failed to fetch name" });
  }
};
//----------------------------------------------------------------------


//----------------------------------------------------------------------
// PARENT LOGIN (with bcrypt compare)
// --------------------------------------------------------------------
exports.loginParent = async (req, res) => {
const { phoneNo, password } = req.body;

if (!validatePhone(phoneNo))
return res.status(400).json({ error: "Invalid phone number format" });

if (!password)
return res.status(400).json({ error: "Password is required" });

try {
const result = await sql`
SELECT parentId, password
FROM "Parent"
WHERE phoneNo = ${phoneNo} 
`;

if (result.length === 0)
return res.status(404).json({ message: "Parent not found" });

const parent = result[0];

// ✅ مقارنة الباسوورد المشفّر
const isMatch = await bcrypt.compare(password, parent.password);
if (!isMatch)
return res.status(401).json({ message: "Incorrect password" });

res.json({ message: "Parent login successful", parentId: parent.parentid });
} catch (err) {
console.error("❌ Login error:", err);
res.status(500).json({ error: "Failed to login" });
}
};
//----------------------------------------------------------------------
//CHILD LOGIN
// --------------------------------------------------------------------
exports.loginChild = async (req, res) => {
const { phoneNo, password } = req.body;
console.log("📱 Child login request:", req.body);

if (!/^05\d{8}$/.test(phoneNo))
return res.status(400).json({ error: "Invalid phone number format" });

if (!password)
return res.status(400).json({ error: "Password is required" });

try {
const result = await sql`
SELECT childId, password
FROM "Child"
WHERE phoneNo = ${phoneNo}
`;

if (result.length === 0)
return res.status(404).json({ message: "Child not found" });

const child = result[0];
const isMatch = await bcrypt.compare(password, child.password);

if (!isMatch)
return res.status(401).json({ message: "Incorrect password" });

res.json({
message: "Child login successful",
childId: child.childid,
});
} catch (err) {
console.error("❌ Child login error:", err);
res.status(500).json({ error: "Failed to login child" });
}
};

// =====================================================
// GET PARENT INFO BY ID
// =====================================================
exports.getParentInfo = async (req, res) => {
const { parentId } = req.params;

try {
const result = await sql`
SELECT firstName, lastName, phoneNo
FROM "Parent"
WHERE parentId = ${parentId}
`;

if (result.length === 0)
return res.status(404).json({ error: "Parent not found" });

// Fetch wallet balance
const wallet = await sql`
SELECT walletBalance
FROM "Wallet"
WHERE parentId = ${parentId}
`;

const balance = wallet.length > 0 ? wallet[0].walletbalance : 0;

res.json({
firstName: result[0].firstname,
lastName: result[0].lastname,
phoneNo: result[0].phoneno,
balance,
});
} catch (err) {
console.error("Error fetching parent info:", err);
res.status(500).json({ error: "Failed to fetch parent info" });
}
};



exports.forgotPassword = async (req, res) => {
try {
let { phoneNo } = req.body;

console.log("1️⃣ Request received with:", phoneNo);

if (!phoneNo)
return res.status(400).json({ error: "Phone number is required" });

// Normalize phone
phoneNo = phoneNo.trim();
if (phoneNo.startsWith("+966")) {
phoneNo = "0" + phoneNo.slice(4);
}

console.log("2️⃣ Normalized phone:", phoneNo);

// Generate random password
const newPassword = Math.random().toString(36).slice(-8);
console.log("3️⃣ New generated password:", newPassword);

const parent = await sql`SELECT parentId, phoneNo FROM "Parent" WHERE phoneNo = ${phoneNo}`;
console.log("4️⃣ Parent query result:", parent);

if (parent.length === 0)
return res.status(404).json({ error: "Parent not found" });

const saltRounds = 10;
const hashed = await bcrypt.hash(newPassword, saltRounds);

console.log("5️⃣ Hashed password:", hashed);

await sql`
UPDATE "Parent"
SET password = ${hashed}
WHERE phoneNo = ${phoneNo}
`;

console.log("6️⃣ Update done for:", phoneNo);

const check = await sql`SELECT password FROM "Parent" WHERE phoneNo = ${phoneNo}`;
console.log("7️⃣ Password in DB after update:", check);

res.json({ message: "Password reset successful" });
} catch (err) {
console.error("❌ Forgot password error:", err);
res.status(500).json({ error: "Internal error" });
}
};

// =====================================================
// GET CHILD INFO BY ID 
// =====================================================
// =====================================================
// GET CHILD INFO BY ID
// =====================================================
exports.getChildInfo = async (req, res) => {
  const { childId } = req.params;

  try {
    const result = await sql`
      SELECT firstName, phoneNo, points
      FROM "Child"
      WHERE childId = ${childId}
    `;

    if (result.length === 0)
      return res.status(404).json({ error: "Child not found" });

    // ✅ Get wallet + balance breakdown
    const wallet = await sql`
      SELECT walletId, walletBalance
      FROM "Wallet"
      WHERE childId = ${childId}
    `;

    let balance = 0;
    let saving = 0;
    let spend = 0;

    if (wallet.length > 0) {
      balance = wallet[0].walletbalance;

      const breakdown = await sql`
        SELECT 
          COALESCE(savedamount, 0) AS "saving",
          COALESCE(spendamount, 0) AS "spend"
        FROM "BalanceBreakdown"
        WHERE walletId = ${wallet[0].walletid}
      `;

      if (breakdown.length > 0) {
        saving = breakdown[0].saving;
        spend = breakdown[0].spend;
      }
    }

    res.json({
      firstName: result[0].firstname,
      phoneNo: result[0].phoneno,
      balance,
      saving,
      spend,
      points: result[0].points ?? 0,
    });
  } catch (err) {
    console.error("❌ Error fetching child info:", err);
    res.status(500).json({ error: "Failed to fetch child info" });
  }
};




// ----------------------------------------------------------------------
// LOGOUT (temporary)
// ----------------------------------------------------------------------
exports.logout = (req, res) => {
console.log("✅ Logout endpoint hit");
res.json({ message: "Logged out successfully" });
};


// =====================================================
// GET PARENT BY ID
// =====================================================

exports.getParentById = async (req, res) => {
  try {
    const { parentId } = req.params;

    const result = await sql`
      SELECT firstname, lastname, phoneno, nationalid
      FROM "Parent"
      WHERE parentId = ${parentId}
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: "Parent not found" });
    }

    res.json(result[0]);
  } catch (err) {
    console.error("❌ Error fetching parent:", err);
    res.status(500).json({ error: "Failed to fetch parent" });
  }
};

