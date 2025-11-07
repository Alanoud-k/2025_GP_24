const bcrypt = require("bcrypt");
const { sql } = require("../config/db");

// =====================================================
// Get Children by Parent
// =====================================================
exports.getChildrenByParent = async (req, res) => {
  const { parentId } = req.params;
  console.log("📩 Request received for parentId:", parentId);

  try {
    const children = await sql`
      SELECT 
        c.childid AS "childid",
        c.firstname AS "firstname",
        c.phoneno AS "phoneno",
        COALESCE(w.walletbalance, 0) AS "balance"
      FROM "Child" c
      LEFT JOIN "Wallet" w ON c.childid = w.childid
      WHERE c.parentid = ${parentId};
    `;

    console.log("✅ Query result:", children);
    res.status(200).json(children);
  } catch (err) {
    console.error("❌ Error fetching children:", err);
    res.status(500).json({ error: err.message });
  }
};





// =====================================================
// Register Child (with hashed PIN)
// =====================================================
exports.registerChild = async (req, res) => {
  const { parentId, firstName, nationalId, phoneNo, dob, password } = req.body;

  if (!parentId || !firstName || !nationalId || !phoneNo || !dob || !password)
    return res.status(400).json({ error: "All fields are required" });

  // basic validations
  if (!/^[a-zA-Z]+$/.test(firstName))
    return res.status(400).json({ error: "First name must contain only letters" });

  if (!/^05\d{8}$/.test(phoneNo))
    return res.status(400).json({ error: "Invalid phone number format" });

  // Check child is under 18
  const birthDate = new Date(dob);
  const age = new Date().getFullYear() - birthDate.getFullYear();
  if (age >= 18)
    return res.status(400).json({ error: "Child must be under 18 years old" });

  try {
    // Validate National ID
    const national = await sql`
      SELECT * FROM "National_Id"
      WHERE nationalId = ${nationalId} AND valid = true
    `;
    if (national.length === 0)
      return res.status(400).json({ error: "Invalid or already used National ID" });

    // Ensure phone number uniqueness
    const existing = await sql`SELECT * FROM "Child" WHERE phoneNo = ${phoneNo}`;
    if (existing.length > 0)
      return res.status(400).json({ error: "Phone number already in use" });


    const saltRounds = 10;
    const hashedPasswordChild = await bcrypt.hash(password, saltRounds);




    const inserted = await sql`
      INSERT INTO "Child" (parentId, firstName, nationalId, phoneNo, dob, password)
      VALUES (${parentId}, ${firstName}, ${nationalId}, ${phoneNo}, ${dob}, ${hashedPasswordChild})
      RETURNING childId AS "childId"
    `;

    const childId = inserted[0].childId;

    // Create wallet for the child
    await sql`
      INSERT INTO "Wallet" (childId, walletBalance, walletStatus)
      VALUES (${childId}, 0.0, 'Active')
    `;

    // Mark National ID as used
    await sql`
      UPDATE "National_Id"
      SET valid = false
      WHERE nationalId = ${nationalId}
    `;

    res.json({ message: "Child registered successfully", childId });
  } catch (err) {
    console.error("Error registering child:", err);
    res.status(500).json({ error: "Failed to register child" });
  }
};




