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

// parent registration logic
exports.registerParent = async (req, res) => {
  const { firstName, lastName, nationalId, DoB, phoneNo, password } = req.body;

  if (!firstName || !lastName || !nationalId || !DoB || !phoneNo || !password)
    return res.status(400).json({ error: "All fields are required" });

  if (!validatePhone(phoneNo)) {
    return res.status(400).json({ error: "Invalid phone number format" });
  }

  if (!validatePassword(password))
    return res.status(400).json({ error: "Weak password" });

  try {
    //check if phoneNo already exists
    const existingParent = await sql`SELECT * FROM "Parent" WHERE phoneNo = ${phoneNo}`;
    if (existingParent.length > 0)
      return res.status(400).json({ error: "Phone number already registered" });

    //validate national id
    const validNational = await sql`
      SELECT * FROM "National_Id"
      WHERE nationalId = ${nationalId} AND valid = true
    `;
    if (validNational.length === 0) {
      return res.status(400).json({ error: "Invalid or unverified National ID" });
    }
    //insert new parent
    const result = await sql`
      INSERT INTO "Parent" (nationalId, phoneNo, firstName, lastName, "DoB", password)
      VALUES (${nationalId}, ${phoneNo}, ${firstName}, ${lastName}, ${DoB}, ${password})
      RETURNING parentId
    `;

    const newParentId = result[0].parentId;

    //create a wallet for the parent
    await sql`
      INSERT INTO "Wallet" (parentId, walletBalance, currency)
      VALUES (${newParentId}, 0, 'SAR')
    `;

    res.json({ message: "Parent registered successfully", parentId: newParentId });
  } catch (err) {
    console.error("❌ Registration error:", err);
    res.status(500).json({ error: "Failed to register parent" });
  }
};
