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
      return res.status(400).json({ error: "Invalid or already used National ID" });

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
// PARENT LOGIN (with bcrypt compare)
// --------------------------------------------------------------------
exports.loginParent = async (req, res) => {
  const { phoneNo, nationalId, password } = req.body;

  if (!validatePhone(phoneNo))
    return res.status(400).json({ error: "Invalid phone number format" });

  if (!password)
    return res.status(400).json({ error: "Password is required" });

  try {
    const result = await sql`
      SELECT parentId, password
      FROM "Parent"
      WHERE phoneNo = ${phoneNo} AND nationalId = ${nationalId}
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
  const { phoneNo, PIN } = req.body;

  if (!/^05\d{8}$/.test(phoneNo))
    return res.status(400).json({ error: "Invalid phone number format" });

  if (!PIN)
    return res.status(400).json({ error: "PIN is required" });

  try {
    const result = await sql`
      SELECT childId, pin
      FROM "Child"
      WHERE phoneNo = ${phoneNo}
    `;

    if (result.length === 0)
      return res.status(404).json({ message: "Child not found" });

    const child = result[0];
    const isMatch = await bcrypt.compare(PIN, child.pin);

    if (!isMatch)
      return res.status(401).json({ message: "Incorrect PIN" });

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

// ----------------------------------------------------------------------
// LOGOUT (temporary)
// ----------------------------------------------------------------------
exports.logout = (req, res) => {
  console.log("✅ Logout endpoint hit");
  res.json({ message: "Logged out successfully" });
};


