const { sql } = require("../config/db");
const { validatePhone, validatePassword } = require("../utils/validators");

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
    else{
      return res.json({ exists: false });
    }
  } catch (err) {
    console.error("Error checking user:", err);
    res.status(500).json({ error: "Error checking user" });
  }
};


//----------------------------------------------------------------------
// PARENT REGISTRATION
// --------------------------------------------------------------------

exports.registerParent = async (req, res) => {
  const { firstName, lastName, nationalId, DoB, phoneNo, password } = req.body;

  if (!firstName || !lastName || !nationalId || !DoB || !phoneNo || !password)
    return res.status(400).json({ error: "All fields are required" });

  if (!validatePhone(phoneNo))
    return res.status(400).json({ error: "Invalid phone number format" });

  if (!validatePassword(password))
    return res.status(400).json({ error: "Weak password" });

  try {
    // Check if phone number already registered
    const existing = await sql`SELECT * FROM "Parent" WHERE phoneNo = ${phoneNo}`;
    if (existing.length > 0)
      return res.status(400).json({ error: "Phone number already registered" });

    // Validate national ID
    const national = await sql`
      SELECT * FROM "National_Id"
      WHERE nationalId = ${nationalId} AND valid = true
    `;
    if (national.length === 0)
      return res.status(400).json({ error: "Invalid or unverified National ID" });

    // Insert parent and return id
    const inserted = await sql`
      INSERT INTO "Parent" (nationalId, phoneNo, firstName, lastName, "DoB", password)
      VALUES (${nationalId}, ${phoneNo}, ${firstName}, ${lastName}, ${DoB}, ${password})
      RETURNING parentId AS "parentId"
    `;
    const newParentId = inserted[0].parentId;

    // Create wallet with foreign key
    await sql`
      INSERT INTO "Wallet" (parentId, walletBalance, currency)
      VALUES (${newParentId}, 0, 'SAR')
    `;

    // Mark National ID as used
    await sql`
      UPDATE "National_Id"
      SET valid = false
      WHERE nationalId = ${nationalId}
    `;

    res.json({ message: "Parent registered successfully", parentId: newParentId });
  } catch (err) {
    console.error("❌ Registration error:", err);
    res.status(500).json({ error: "Failed to register parent" });
  }
};



// =====================================================
// PARENT LOGIN
// =====================================================

exports.loginParent = async (req, res) => {
  const { phoneNo, password } = req.body;

  if (!validatePhone(phoneNo))
    return res.status(400).json({ error: "Invalid phone number format" });

  if (!password)
    return res.status(400).json({ error: "Password is required" });

  try {
    // check if the parent exists
    const result = await sql`
      SELECT parentId, password
      FROM "Parent"
      WHERE phoneNo = ${phoneNo}
    `;

    if (result.length === 0)
      return res.status(404).json({ message: "Parent not found" });

    const parent = result[0];

    //Replace with bcrypt.compare() when you hash passwords
    if (parent.password !== password)
      return res.status(401).json({ message: "Incorrect password" });

    // Optionally create session entry here later
    res.json({ message: "Parent login successful", parentId: parent.parentid });
  } catch (err) {
    console.error("❌ Login error:", err);
    res.status(500).json({ error: "Failed to login" });
  }
};

exports.loginChild = async (req, res) => {
  const { phoneNo, PIN } = req.body;
  console.log("📞 Child login attempt:", phoneNo, PIN); // add this

  if (!phoneNo || !PIN)
    return res.status(400).json({ error: "Phone number and PIN are required" });

  try {
    const child = await sql`
      SELECT * FROM "Child" WHERE phoneNo = ${phoneNo}
    `;

    console.log("🔍 Query result:", child);

    if (child.length === 0) {
      console.log("❌ Child not found");
      return res.status(404).json({ error: "Child not found" });
    }

    const storedPin = child[0].pin?.trim(); // 👈 ensures whitespace removed
    console.log("🧩 Stored PIN:", storedPin);

    if (storedPin !== PIN) {
      console.log("❌ Invalid PIN entered");
      return res.status(401).json({ error: "Invalid PIN" });
    }

    console.log("✅ Child login successful!");
    res.json({
      message: "Child login successful",
      childId: child[0].childid,
      parentId: child[0].parentid,
    });
  } catch (err) {
    console.error("❌ Child login error:", err);
    res.status(500).json({ error: "Failed to login child" });
  }
};
