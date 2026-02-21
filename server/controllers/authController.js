// server/controllers/authController.js  (ESM)

import bcrypt from "bcrypt";
import { sql } from "../config/db.js";
import {
  validatePhone,
  validatePassword,
  validateName,
} from "../utils/validators.js";

import jwt from "jsonwebtoken";

function generateToken(payload) {
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || "2h",
  });
}

/* ============================================================
   CHECK USER (by phone)
   Body: { phoneNo }
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
    return res.status(500).json({ error: "Error checking user" });
  }
};

/* ============================================================
   PARENT REGISTRATION
============================================================ */
export const registerParent = async (req, res) => {
  const {
    firstName,
    lastName,
    nationalId,
    DoB,
    phoneNo,
    password,
    securityAnswer,
  } = req.body;

  if (
    !firstName ||
    !lastName ||
    !nationalId ||
    !DoB ||
    !phoneNo ||
    !password ||
    !securityAnswer
  ) {
    return res.status(400).json({ error: "All fields are required" });
  }
  if (!validatePhone(phoneNo)) {
    return res.status(400).json({ error: "Invalid phone number format" });
  }
  if (!validatePassword(password)) {
    return res.status(400).json({ error: "Weak password" });
  }
  if (!validateName(firstName)) {
    return res.status(400).json({ error: "Invalid first name" });
  }
  if (!validateName(lastName)) {
    return res.status(400).json({ error: "Invalid last name" });
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
      return res
        .status(400)
        .json({ error: "Phone number already registered" });
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

    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    const hashedAnswer = await bcrypt.hash(securityAnswer, saltRounds);

    const inserted = await sql`
      INSERT INTO "Parent" (
        "nationalid",
        "phoneno",
        "firstname",
        "lastname",
        "DoB",
        "password",
        "securityanswerhash"
      )
      VALUES (
        ${nationalId},
        ${phoneNo},
        ${firstName},
        ${lastName},
        ${DoB},
        ${hashedPassword},
        ${hashedAnswer}
      )
      RETURNING "parentid"
    `;
    const newParentId = inserted[0].parentid;

    // Create wallet + ParentAccount
    const parentWallet = await sql`
      INSERT INTO "Wallet"("parentid","childid","walletstatus")
      VALUES (${newParentId}, NULL, 'Active')
      RETURNING "walletid"
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

    return res.json({
      message: "Parent registered successfully",
      parentId: newParentId,
    });
  } catch (err) {
    console.error("Registration error:", err);
    return res.status(500).json({ error: "Failed to register parent" });
  }
};

/* ============================================================
   GET NAME BY PHONE
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
    return res.status(500).json({ error: "Failed to fetch name" });
  }
};

/* ============================================================
   PARENT LOGIN
============================================================ */
export const loginParent = async (req, res) => {
  const { phoneNo, password } = req.body;

  if (!validatePhone(phoneNo)) {
    return res.status(400).json({ error: "Invalid phone format" });
  }

  try {
    const result = await sql`
      SELECT "parentid","password"
      FROM "Parent"
      WHERE "phoneno" = ${phoneNo}
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

    return res.json({
      message: "Child login successful",
      childId: child.childid,
      token,
    });
  } catch (err) {
    console.error("❌ Child login error:", err);
    return res.status(500).json({ error: "Failed to login child" });
  }
};

/* ============================================================
   PARENT INFO WITH WALLET TOTAL (auth version)
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

    return res.json({
      firstName: result[0].firstname,
      lastName: result[0].lastname,
      phoneNo: result[0].phoneno,
      balance,
    });
  } catch (err) {
    console.error("Error fetching parent info:", err);
    return res.status(500).json({ error: "Failed to fetch parent info" });
  }
};

/* ============================================================
   VERIFY SECURITY QUESTION ANSWER
============================================================ */
export const verifySecurityAnswer = async (req, res) => {
  const { phoneNo, answer } = req.body;

  if (!phoneNo || !answer) {
    return res
      .status(400)
      .json({ error: "Phone number and answer are required" });
  }

  try {
    const parent = await sql`
      SELECT "securityanswerhash"
      FROM "Parent"
      WHERE "phoneno" = ${phoneNo}
      LIMIT 1
    `;

    if (parent.length > 0) {
      const isMatch = await bcrypt.compare(
        answer,
        parent[0].securityanswerhash
      );
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
      const isMatch = await bcrypt.compare(
        answer,
        child[0].securityanswerhash
      );
      return isMatch
        ? res.json({ verified: true, role: "Child" })
        : res.status(401).json({ error: "Incorrect answer" });
    }

    return res.status(404).json({ error: "User not found" });
  } catch (err) {
    console.error("❌ Error verifying security answer:", err);
    return res.status(500).json({ error: "Internal error" });
  }
};

/* ============================================================
   RESET PASSWORD (after verifying answer)
============================================================ */
export const resetPassword = async (req, res) => {
  const { phoneNo, newPassword } = req.body;

  if (!phoneNo || !newPassword) {
    return res
      .status(400)
      .json({ error: "Phone number and new password are required" });
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
    return res.status(500).json({ error: "Failed to reset password" });
  }
};

/* ============================================================
   LOGOUT (stateless placeholder)
============================================================ */
export const logout = (_req, res) => {
  console.log("✅ Logout endpoint hit");
  return res.json({ message: "Logged out successfully" });
};

/* ============================================================
   GET PARENT BY ID (basic profile)
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

    return res.json(result[0]);
  } catch (err) {
    console.error("❌ Error fetching parent:", err);
    return res.status(500).json({ error: "Failed to fetch parent" });
  }
};

/* ============================================================
   FIXED: Get Children by Parent (correct balance & limit logic)
   Used by: /api/auth/parent/:parentId/children
============================================================ */
/*export const getChildrenByParent = async (req, res) => {
  const { parentId } = req.params;

  try {
    const children = await sql`
      SELECT 
        c."childid"   AS "childId",
        c."firstname" AS "firstName",
        c."phoneno"   AS "phoneNo",

        /* Total wallet balance 
        COALESCE((
          SELECT SUM(a."balance")
          FROM "Account" a
          WHERE a."walletid" = w."walletid"
        ), 0)::float AS "balance",

        /* Spending limit 
        COALESCE((
          SELECT a."limitamount"
          FROM "Account" a
          WHERE a."walletid" = w."walletid"
            AND a."accounttype" = 'SpendingAccount'
          LIMIT 1
        ), 0)::float AS "limitAmount",

        /* Saving balance 
        COALESCE((
          SELECT SUM(a."balance")
          FROM "Account" a
          WHERE a."walletid" = w."walletid"
            AND a."accounttype" = 'SavingAccount'
        ), 0)::float AS "saving",

        /* Spending balance 
        COALESCE((
          SELECT SUM(a."balance")
          FROM "Account" a
          WHERE a."walletid" = w."walletid"
            AND a."accounttype" = 'SpendingAccount'
        ), 0)::float AS "spend"

      FROM "Child" c
      LEFT JOIN "Wallet" w 
        ON w."childid" = c."childid"
      WHERE c."parentid" = ${parentId}
      ORDER BY c."childid" DESC
    `;

    return res.status(200).json(children);

  } catch (err) {
    console.error("❌ Error fetching children:", err);
    return res.status(500).json({
      error: "Failed to fetch children",
      details: err.message,
    });
  }
};*/
/* ============================================================
   UPDATE CHILD SPENDING LIMIT
   Route: PUT /api/auth/child/update-limit/:childId
============================================================ */
/*export const updateChildLimit = async (req, res) => {
  const { childId } = req.params;
  const { limitAmount } = req.body;

  const newLimit = Number(limitAmount);

  if (!Number.isFinite(newLimit) || newLimit <= 0) {
    return res.status(400).json({ error: "Limit amount must be a positive number" });
  }

  try {
    // 1) Get child's wallet
    const wallet = await sql`
      SELECT "walletid"
      FROM "Wallet"
      WHERE "childid" = ${childId}
      LIMIT 1
    `;

    if (wallet.length === 0) {
      return res.status(404).json({ error: "Wallet not found for this child" });
    }

    const walletId = wallet[0].walletid;

    // 2) Update limitamount in SpendingAccount
    await sql`
      UPDATE "Account"
      SET "limitamount" = ${newLimit}
      WHERE "walletid" = ${walletId}
        AND "accounttype" = 'SpendingAccount'
    `;

    return res.json({ message: "Child spending limit updated", limitAmount: newLimit });

  } catch (err) {
    console.error("❌ Error updating limit:", err);
    return res.status(500).json({ error: "Failed to update limit", details: err.message });
  }
};*/

export const updateChildLimit = async (req, res) => {
  const { childId } = req.params;
  const { limitAmount, defaultSavingRatio } = req.body;

  const newLimit = Number(limitAmount);
  const ratio = Number(defaultSavingRatio);

  if (!Number.isFinite(newLimit) || newLimit <= 0) {
    return res.status(400).json({
      error: "Limit amount must be a positive number"
    });
  }

  if (!Number.isFinite(ratio) || ratio < 0 || ratio > 1) {
    return res.status(400).json({
      error: "Saving ratio must be between 0 and 1"
    });
  }

  try {
    // 1) Get wallet
    const wallet = await sql`
      SELECT "walletid"
      FROM "Wallet"
      WHERE "childid" = ${childId}
      LIMIT 1
    `;

    if (wallet.length === 0) {
      return res.status(404).json({
        error: "Wallet not found for this child"
      });
    }

    const walletId = wallet[0].walletid;

    // 2) Update limit
    await sql`
      UPDATE "Account"
      SET "limitamount" = ${newLimit}
      WHERE "walletid" = ${walletId}
        AND "accounttype" = 'SpendingAccount'
    `;

    // 3) Update saving ratio
    await sql`
      UPDATE "Child"
      SET "default_saving_ratio" = ${ratio}
      WHERE "childid" = ${childId}
    `;

    return res.json({
      message: "Child settings updated",
      limitAmount: newLimit,
      defaultSavingRatio: ratio
    });

  } catch (err) {
    console.error("❌ Error updating child settings:", err);
    return res.status(500).json({
      error: "Failed to update child settings",
      details: err.message
    });
  }
};

