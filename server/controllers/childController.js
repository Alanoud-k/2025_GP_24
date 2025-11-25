// server/controllers/childController.js  (ESM)

import bcrypt from "bcrypt";
import { sql } from "../config/db.js";
import cloudinary from "../config/cloudinary.js";

/* =====================================================
   Get Children by Parent
   Params: :parentId
   Returns each child with aggregated wallet balance
===================================================== */
export const getChildrenByParent = async (req, res) => {
  const { parentId } = req.params;
  try {
    const children = await sql`
      SELECT 
        c."childid"   AS "childId",
        c."firstname" AS "firstName",
        c."phoneno"   AS "phoneNo",
        COALESCE((
          SELECT SUM(a."balance")
          FROM "Account" a
          WHERE a."walletid" = w."walletid"
        ), 0) AS "balance"
      FROM "Child" c
      LEFT JOIN "Wallet" w ON w."childid" = c."childid"
      WHERE c."parentid" = ${parentId}
      ORDER BY c."childid" DESC
    `;
    res.status(200).json(children);
  } catch (err) {
    console.error("❌ Error fetching children:", err);
    res.status(500).json({ error: "Failed to fetch children" });
  }
};

/* =====================================================
   Register Child (with hashed password/PIN)
   Body: { parentId, firstName, nationalId, phoneNo, dob, password }
===================================================== */
export const registerChild = async (req, res) => {
  const { parentId, firstName, nationalId, phoneNo, dob, password, limitAmount  } = req.body;

  if (!parentId || !firstName || !nationalId || !phoneNo || !dob || !password) {
    return res.status(400).json({ error: "All fields are required" });
  }
  if (!/^[A-Za-zأ-يء\s]+$/.test(firstName)) {
    return res.status(400).json({ error: "First name must contain only letters" });
  }
  if (!/^05\d{8}$/.test(phoneNo)) {
    return res.status(400).json({ error: "Invalid phone number format" });
  }

  // Age must be < 18
  const birthDate = new Date(dob);
  const now = new Date();
  let age = now.getFullYear() - birthDate.getFullYear();
  const m = now.getMonth() - birthDate.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < birthDate.getDate())) age--;
  if (age >= 18) {
    return res.status(400).json({ error: "Child must be under 18 years old" });
  }

  try {
    // National ID must exist and be valid=true
    const nat = await sql`
      SELECT "valid" FROM "National_Id"
      WHERE "nationalid" = ${nationalId} AND "valid" = true
      LIMIT 1
    `;
    if (nat.length === 0) {
      return res.status(400).json({ error: "Invalid or already used National ID" });
    }

    // Unique phone for Child
    const existing = await sql`
      SELECT 1 FROM "Child" WHERE "phoneno" = ${phoneNo} LIMIT 1
    `;
    if (existing.length > 0) {
      return res.status(400).json({ error: "Phone number already in use" });
    }

    // Hash password
    const hashed = await bcrypt.hash(password, 10);

    if (!limitAmount || isNaN(limitAmount) || limitAmount <= 0) {
  return res.status(400).json({ error: "Limit amount must be a positive number" });
}

    // Insert child (columns follow your schema)
    const inserted = await sql`
      INSERT INTO "Child" ("parentid","firstname","nationalid","phoneno","dob","password")
      VALUES (${parentId}, ${firstName}, ${nationalId}, ${phoneNo}, ${dob}, ${hashed})
      RETURNING "childid"
    `;
    const childId = inserted[0].childid;

    // Create wallet (Active)
const walletInsert = await sql`
INSERT INTO "Wallet" ("parentid","childid","walletstatus")
VALUES (NULL, ${childId}, 'Active')
  RETURNING "walletid"
`;
const walletId = walletInsert[0].walletid;

// Create saving account (no limit)
await sql`
  INSERT INTO "Account" ("walletid", "accounttype", "balance", "currency")
  VALUES (${walletId}, 'SavingAccount', 0, 'SAR')
`;

// Create spending account with limitamount
await sql`
  INSERT INTO "Account" ("walletid", "accounttype", "balance", "currency", "limitamount")
  VALUES (${walletId}, 'SpendingAccount', 0, 'SAR', ${limitAmount})
`;

    // Mark national id as used
    await sql`
      UPDATE "National_Id" SET "valid" = false
      WHERE "nationalid" = ${nationalId}
    `;

    res.json({ message: "Child registered successfully", childId });
  } catch (err) {
    console.error("❌ Error registering child:", err);
    res.status(500).json({ error: "Failed to register child" });
  }
};

/* =====================================================
   Get Child Info (for ChildHomePage)
   Params: :childId
   - Returns: firstName, phoneNo, balance(total), saving, spend,
     rewardKeys, and spend categories %
===================================================== */
export const getChildInfo = async (req, res) => {
  const { childId } = req.params;
console.log("💚 CHILD CONTROLLER CHILD INFO");

  try {
    // Basic child profile
    const childRows = await sql`
      SELECT 
        "firstname",
        "phoneno",
        "rewardkeys"
      FROM "Child"
      WHERE "childid" = ${childId}
      LIMIT 1
    `;
    if (childRows.length === 0) {
      return res.status(404).json({ error: "Child not found" });
    }
    const child = childRows[0];

    // Get wallet
    const w = await sql`
      SELECT "walletid"
      FROM "Wallet"
      WHERE "childid" = ${childId}
      LIMIT 1
    `;
    let balance = 0;
    let saving = 0;
    let spend = 0;
    let categories = {};

    if (w.length > 0) {
      const walletId = w[0].walletid;

      // Total balance = sum of all accounts under wallet
      const total = await sql`
        SELECT COALESCE(SUM("balance"), 0) AS total
        FROM "Account"
        WHERE "walletid" = ${walletId}
      `;
      balance = Number(total[0]?.total ?? 0);

      // Split by account type
      const splits = await sql`
        SELECT "accounttype", COALESCE(SUM("balance"),0) AS amt
        FROM "Account"
        WHERE "walletid" = ${walletId}
          AND "accounttype" IN ('SavingAccount','SpendingAccount')
        GROUP BY "accounttype"
      `;
      for (const r of splits) {
        if (r.accounttype === "SavingAccount") saving = Number(r.amt);
        if (r.accounttype === "SpendingAccount") spend = Number(r.amt);
      }

      // Spending categories from transactions that land in the child's SpendingAccount
      const spAcc = await sql`
        SELECT "accountid" FROM "Account"
        WHERE "walletid" = ${walletId} AND "accounttype" = 'SpendingAccount'
        LIMIT 1
      `;
      if (spAcc.length > 0) {
        const spendingAccountId = spAcc[0].accountid;

        const catRows = await sql`
          SELECT "transactioncategory" AS category,
                 COALESCE(SUM("amount"),0) AS total
          FROM "Transaction"
          WHERE "receiverAccountId" = ${spendingAccountId}
            AND "transactionstatus" = 'Completed'
          GROUP BY "transactioncategory"
        `;
        const sumAll = catRows.reduce((s, r) => s + Number(r.total), 0);
        for (const r of catRows) {
          const pct = sumAll > 0 ? (Number(r.total) / sumAll) * 100 : 0;
          categories[r.category || "Unlabeled"] = Number(pct.toFixed(1));
        }

        // Fallback sample if no transactions exist
        if (Object.keys(categories).length === 0) {
          categories = { Food: 25, Shopping: 55, Gifts: 10, Others: 10 };
        }
      }
    }

    return res.json({
      firstName: child.firstname,
      phoneNo: child.phoneno,
      //avatarUrl: child.avatarurl ?? null, // CHANGED: send avatarUrl to client
      balance,
      saving,
      spend,
      rewardKeys: child.rewardkeys ?? 0,
      categories,
    });
  } catch (err) {
    console.error("❌ Error fetching child info:", err);
    res.status(500).json({ error: "Failed to fetch child info" });
  }
};

/* =====================================================
   UPDATE CHILD AVATAR
   Route: POST /api/auth/child/upload-avatar/:childId
   File: avatar (image)
===================================================== */
/*export const updateChildAvatar = async (req, res) => {
  const { childId } = req.params;

  try {
    if (!req.file) {
      return res.status(400).json({ error: "No image uploaded" });
    }

    // 1) Upload to Cloudinary
    const result = await cloudinary.uploader.upload(req.file.path, {
      folder: "hassala/avatars",
      transformation: [{ width: 300, height: 300, crop: "fill" }],
    });

    // 2) secure URL
    const avatarUrl = result.secure_url;

    // 3) Save into Neon DB
    await sql`
      UPDATE "Child"
      SET "avatarurl" = ${avatarUrl}
      WHERE "childid" = ${childId}
    `;

    res.json({
      message: "Avatar updated successfully",
      avatarUrl,
    });

    const childRows = await sql`
  SELECT "firstname","phoneno","rewardkeys","avatarurl"
  FROM "Child"
  WHERE "childid" = ${childId}
  LIMIT 1
`;

  } catch (err) {
    console.error("❌ Cloudinary upload error:", err);
    res.status(500).json({ error: "Failed to upload avatar" });
  }
};*/
