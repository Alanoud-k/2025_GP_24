const { sql } = require("../config/db");

exports.getChildrenByParent = async (req, res) => {
  const { parentId } = req.params;

  try {
    const children = await sql`
      SELECT childId, firstName, phoneNo, dob
      FROM "Child"
      WHERE parentId = ${parentId}
    `;
    res.json(children);
  } catch (err) {
    console.error("Error fetching children:", err);
    res.status(500).json({ error: "Failed to fetch children" });
  }
};

exports.registerChild = async (req, res) => {
  const { parentId, firstName, nationalId, phoneNo, dob, PIN } = req.body;

  if (!parentId || !firstName || !nationalId || !phoneNo || !dob || !PIN)
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

    // Insert child
    const childResult = await pool.query(
  `INSERT INTO "Child" (parentId, firstName, nationalId, phoneNo, dob, pin)
   VALUES ($1, $2, $3, $4, $5, $6)
   RETURNING childId`,
  [parentId, firstName, nationalId, phoneNo, dob, pin]
);


   const childId = childResult.rows[0].childid;

// Create wallet for the child
await pool.query(
  `INSERT INTO "Wallet" (childId, balance, status)
   VALUES ($1, 0.0, 'Active')`,
  [childId]
);


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
