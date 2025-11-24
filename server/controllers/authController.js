// server/controllers/authController.js  (ESM)

import bcrypt from "bcrypt";
import { sql } from "../config/db.js";
import { validatePhone, validatePassword } from "../utils/validators.js";



import jwt from "jsonwebtoken";

function generateToken(payload) {
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || "2h",
  });
}




/* ============================================================
   CHECK USER (by phone)
   Body: { phoneNo }
   Returns: { exists: boolean, role?: 'Parent'|'Child' }
============================================================ */
export const checkUser = async (req, res) => {
  const { phoneNo } = req.body;

  if (!validatePhone(phoneNo)) {
    return res.status(400).json({ error: "Invalid phone number format" });
  }

  try {
    const parent = await sql`
      SELECT 1 FROM "Parent"
      WHERE "phoneno" = ${phoneNo}
      LIMIT 1
    `;
    if (parent.length > 0) return res.json({ exists: true, role: "Parent" });

    const child = await sql`
      SELECT 1 FROM "Child"
      WHERE "phoneno" = ${phoneNo}
      LIMIT 1
    `;
    if (child.length > 0) return res.json({ exists: true, role: "Child" });

    return res.json({ exists: false });
  } catch (err) {
    console.error("Error checking user:", err);
    res.status(500).json({ error: "Error checking user" });
  }
};

/* ============================================================
   PARENT REGISTRATION
   Body: { firstName, lastName, nationalId, DoB, phoneNo, password }
============================================================ */
export const registerParent = async (req, res) => {
  const { firstName, lastName, nationalId, DoB, phoneNo, password, securityAnswer } = req.body;

  // Basic validations
  if (!firstName || !lastName || !nationalId || !DoB || !phoneNo || !password) {
    return res.status(400).json({ error: "All fields are required" });
  }
  if (!validatePhone(phoneNo)) {
    return res.status(400).json({ error: "Invalid phone number format" });
  }
  if (!validatePassword(password)) {
    return res.status(400).json({ error: "Weak password" });
  }

  // Age check (>= 18)
  const birthDate = new Date(DoB);
  const now = new Date();
  let age = now.getFullYear() - birthDate.getFullYear();
  const m = now.getMonth() - birthDate.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < birthDate.getDate())) age--;
  if (age < 18) {
    return res
      .status(400)
      .json({ error: "Parent must be at least 18 years old" });
  }

  try {
    // Unique phone
    const existing = await sql`
      SELECT 1 FROM "Parent"
      WHERE "phoneno" = ${phoneNo}
      LIMIT 1
    `;
    if (existing.length > 0) {
      return res.status(400).json({ error: "Phone number already registered" });
    }

    // National Id valid?
    const national = await sql`
      SELECT "valid"
      FROM "National_Id"
      WHERE "nationalid" = ${nationalId}
        AND "valid" = true
      LIMIT 1
    `;
    if (national.length === 0) {
      return res
        .status(400)
        .json({ error: "National ID not found or already used" });
    }

    // Hash password and security answer
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    const hashedAnswer = await bcrypt.hash(securityAnswer, saltRounds);

    // Insert parent with security answer hash
    const inserted = await sql`
  INSERT INTO "Parent" (
    "nationalid", "phoneno", "firstname", "lastname", "DoB", "password", "securityanswerhash"
  )
  VALUES (
    ${nationalId}, ${phoneNo}, ${firstName}, ${lastName}, ${DoB}, ${hashedPassword}, ${hashedAnswer}
  )
  RETURNING "parentid"
`;
    const newParentId = inserted[0].parentid;


    // Create wallet row for parent
    const parentWallet = await sql`
  INSERT INTO "Wallet"("parentid","childid","walletstatus")
  VALUES (${newParentId}, NULL, 'Active')
  RETURNING walletid
`;

    await sql`
  INSERT INTO "Account"("walletid","accounttype","currency","balance","limitamount")
  VALUES (${parentWallet[0].walletid}, 'ParentAccount', 'SAR', 0, 0)
`;

    // Mark national id as used
    await sql`
      UPDATE "National_Id"
      SET "valid" = false
      WHERE "nationalid" = ${nationalId}
    `;

    res.json({
      message: "Parent registered successfully",
      parentId: newParentId,
    });
  } catch (err) {
    console.error("Registration error:", err);
    res.status(500).json({ error: "Failed to register parent" });
  }
};

/* ============================================================
   GET NAME BY PHONE
   Route param: :phoneNo
============================================================ */
export const getNameByPhone = async (req, res) => {
  const { phoneNo } = req.params;
  try {
    const parent = await sql`
      SELECT "firstname"
      FROM "Parent"
      WHERE "phoneno" = ${phoneNo}
      LIMIT 1
    `;
    if (parent.length > 0) {
      return res.json({ firstName: parent[0].firstname });
    }

    const child = await sql`
      SELECT "firstname"
      FROM "Child"
      WHERE "phoneno" = ${phoneNo}
      LIMIT 1
    `;
    if (child.length > 0) {
      return res.json({ firstName: child[0].firstname });
    }

    return res.status(404).json({ error: "User not found" });
  } catch (err) {
    console.error("Error fetching firstName:", err);
    res.status(500).json({ error: "Failed to fetch name" });
  }
};

/* ============================================================
   PARENT LOGIN
   Body: { phoneNo, password }
============================================================ */
export const loginParent = async (req, res) => {
  const { phoneNo, password } = req.body;

  if (!validatePhone(phoneNo)) {
    return res.status(400).json({ error: "Invalid phone format" });
  }

  try {
    const result = await sql`
      SELECT parentid, password
      FROM "Parent"
      WHERE phoneno = ${phoneNo}
      LIMIT 1
    `;

    if (result.length === 0) {
      return res.status(404).json({ message: "Parent not found" });
    }

    const parent = result[0];
    const isMatch = await bcrypt.compare(password, parent.password);

    if (!isMatch) {
      return res.status(401).json({ message: "Incorrect password" });
    }

    // CORRECT TOKEN
    const token = generateToken({ id: parent.parentid, role: "Parent" });


    return res.json({
      message: "Parent login successful",
      parentId: parent.parentid,
      token,
    });

  } catch (err) {
    console.error("Login error:", err);
    return res.status(500).json({ error: "Failed to login" });
  }
};


/* ============================================================
   CHILD LOGIN
   Body: { phoneNo, password }
============================================================ */


export const loginChild = async (req, res) => {
  const { phoneNo, password } = req.body;

  if (!/^05\d{8}$/.test(phoneNo)) {
    return res.status(400).json({ error: "Invalid phone number format" });
  }
  if (!password) {
    return res.status(400).json({ error: "Password is required" });
  }

  try {
    const result = await sql`
      SELECT "childid","password"
      FROM "Child"
      WHERE "phoneno" = ${phoneNo}
      LIMIT 1
    `;

    if (result.length === 0) {
      return res.status(404).json({ message: "Child not found" });
    }

    const child = result[0];
    const isMatch = await bcrypt.compare(password, child.password);

    if (!isMatch) {
      return res.status(401).json({ message: "Incorrect password" });
    }

 const token = generateToken({ id: child.childid, role: "Child" });


    res.json({
      message: "Child login successful",
      childId: child.childid,
      token
    });


  } catch (err) {
    console.error("❌ Child login error:", err);
    res.status(500).json({ error: "Failed to login child" });
  }
};

/* ============================================================
   GET PARENT INFO BY ID (with wallet total balance)
   Params: :parentId
============================================================ */
export const getParentInfo = async (req, res) => {
  const { parentId } = req.params;

  try {
    const result = await sql`
      SELECT "firstname","lastname","phoneno"
      FROM "Parent"
      WHERE "parentid" = ${parentId}
      LIMIT 1
    `;
    if (result.length === 0) {
      return res.status(404).json({ error: "Parent not found" });
    }

    // Find wallet (if exists)
    const wallet = await sql`
      SELECT "walletid"
      FROM "Wallet"
      WHERE "parentid" = ${parentId}
      LIMIT 1
    `;
    let balance = 0;

    if (wallet.length > 0) {
      const walletId = wallet[0].walletid;
      const sum = await sql`
        SELECT COALESCE(SUM("balance"), 0) AS total
        FROM "Account"
        WHERE "walletid" = ${walletId}
      `;
      balance = Number(sum[0]?.total ?? 0);
    }

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

/* ============================================================
   VERIFY SECURITY QUESTION ANSWER
   Body: { phoneNo, answer }
============================================================ */
export const verifySecurityAnswer = async (req, res) => {
  const { phoneNo, answer } = req.body;

  if (!phoneNo || !answer) {
    return res.status(400).json({ error: "Phone number and answer are required" });
  }

  try {
    const parent = await sql`
      SELECT "securityanswerhash"
      FROM "Parent"
      WHERE "phoneno" = ${phoneNo}
      LIMIT 1
    `;

    if (parent.length > 0) {
      const isMatch = await bcrypt.compare(answer, parent[0].securityanswerhash);
      return isMatch
        ? res.json({ verified: true, role: "Parent" })
        : res.status(401).json({ error: "Incorrect answer" });
    }

    const child = await sql`
      SELECT "securityanswerhash"
      FROM "Child"
      WHERE "phoneno" = ${phoneNo}
      LIMIT 1
    `;

    if (child.length > 0) {
      const isMatch = await bcrypt.compare(answer, child[0].securityanswerhash);
      return isMatch
        ? res.json({ verified: true, role: "Child" })
        : res.status(401).json({ error: "Incorrect answer" });
    }

    return res.status(404).json({ error: "User not found" });
  } catch (err) {
    console.error("❌ Error verifying security answer:", err);
    res.status(500).json({ error: "Internal error" });
  }
};

/* ============================================================
   RESET PASSWORD (after verifying answer)
   Body: { phoneNo, newPassword }
============================================================ */
export const resetPassword = async (req, res) => {
  const { phoneNo, newPassword } = req.body;

  if (!phoneNo || !newPassword) {
    return res.status(400).json({ error: "Phone number and new password are required" });
  }

  if (!validatePassword(newPassword)) {
    return res.status(400).json({ error: "Weak password" });
  }

  try {
    const hashed = await bcrypt.hash(newPassword, 10);

    const updatedParent = await sql`
      UPDATE "Parent"
      SET "password" = ${hashed}
      WHERE "phoneno" = ${phoneNo}
      RETURNING "parentid"
    `;
    if (updatedParent.length > 0) {
      return res.json({ message: "Password reset for Parent" });
    }

    const updatedChild = await sql`
      UPDATE "Child"
      SET "password" = ${hashed}
      WHERE "phoneno" = ${phoneNo}
      RETURNING "childid"
    `;
    if (updatedChild.length > 0) {
      return res.json({ message: "Password reset for Child" });
    }

    return res.status(404).json({ error: "User not found" });
  } catch (err) {
    console.error("❌ Reset password error:", err);
    res.status(500).json({ error: "Failed to reset password" });
  }
};

/* ============================================================
   GET CHILD INFO BY ID (with wallet + saving/spending split)
   Params: :childId
============================================================ */
export const getChildInfo = async (req, res) => {
  const { childId } = req.params;

  try {
    const result = await sql`
      SELECT "firstname","phoneno","rewardkeys","avatarurl"
      FROM "Child"
      WHERE "childid" = ${childId}
      LIMIT 1
    `;
    if (result.length === 0) {
      return res.status(404).json({ error: "Child not found" });
    }

    // Child wallet
    const w = await sql`
      SELECT "walletid"
      FROM "Wallet"
      WHERE "childid" = ${childId}
      LIMIT 1
    `;

    let balance = 0;
    let saving = 0;
    let spend = 0;

    if (w.length > 0) {
      const walletId = w[0].walletid;

      // Total wallet balance
      const total = await sql`
        SELECT COALESCE(SUM("balance"), 0) AS total
        FROM "Account"
        WHERE "walletid" = ${walletId}
      `;
      balance = Number(total[0]?.total ?? 0);

      // Split by account type
      const rows = await sql`
        SELECT "accounttype", COALESCE(SUM("balance"),0) AS amt
        FROM "Account"
        WHERE "walletid" = ${walletId}
          AND "accounttype" IN ('SavingAccount','SpendingAccount')
        GROUP BY "accounttype"
      `;
      for (const r of rows) {
        if (r.accounttype === "SavingAccount") saving = Number(r.amt);
        if (r.accounttype === "SpendingAccount") spend = Number(r.amt);
      }
    }

    res.json({
      firstName: result[0].firstname,
      phoneNo: result[0].phoneno,
      balance,
      saving,
      spend,
      rewardKeys: result[0].rewardkeys ?? 0,
      avatarUrl: result[0].avatarurl ?? null

    });
  } catch (err) {
    console.error("❌ Error fetching child info:", err);
    res.status(500).json({ error: "Failed to fetch child info" });
  }
};

/* ============================================================
   LOGOUT (stateless placeholder)
============================================================ */
export const logout = (_req, res) => {
  console.log("✅ Logout endpoint hit");
  res.json({ message: "Logged out successfully" });
};

/* ============================================================
   GET PARENT BY ID (basic profile)
   Params: :parentId
============================================================ */
export const getParentById = async (req, res) => {
  try {
    const { parentId } = req.params;

    const result = await sql`
      SELECT "firstname","lastname","phoneno","nationalid"
      FROM "Parent"
      WHERE "parentid" = ${parentId}
      LIMIT 1
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
