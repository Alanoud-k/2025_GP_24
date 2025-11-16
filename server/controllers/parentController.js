// server/controllers/parentController.js  (ESM)

import { sql } from "../config/db.js";
import bcrypt from "bcrypt";

// 🟢 Get Parent Info by ID
export const getParentInfo = async (req, res) => {
  try {
    const { parentId } = req.params;

    const result = await sql`
      SELECT firstname, lastname, phoneno, nationalid
      FROM "Parent"
      WHERE parentid = ${parentId};
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: "Parent not found" });
    }

    const parent = result[0];

    return res.json({
      firstName: parent.firstname,
      lastName: parent.lastname,
      phoneNo: parent.phoneno,
      nationalId: parent.nationalid,
    });

  } catch (err) {
    return res.status(500).json({
      error: "Failed to fetch parent info",
      details: err.message,
    });
  }
};

// 🟢 Get Children by Parent ID
export const getChildrenByParent = async (req, res) => {
  try {
    const { parentId } = req.params;

    const result = await sql`
      SELECT 
        childid,
        firstname,
        phoneno,
        avatarurl,
        password,
        dob,
        rewardkeys,
        nationalid
      FROM "Child"
      WHERE parentid = ${parentId};
    `;

    return res.json({
      children: result.map(child => ({
        id: child.childid,
        firstName: child.firstname,
        phoneNo: child.phoneno,
        avatarUrl: child.avatarurl,
        password: child.password,
        dob: child.dob,
        rewardKeys: child.rewardkeys,
        nationalId: child.nationalid,
      }))
    });

  } catch (err) {
    return res.status(500).json({
      error: "Failed to fetch children",
      details: err.message,
    });
  }
};

// 🟢 Change Parent Password
export const changeParentPassword = async (req, res) => {
  try {
    const { parentId } = req.params;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: "Current password and new password are required" });
    }

    const parentResult = await sql`
      SELECT password FROM "Parent" WHERE parentid = ${parentId};
    `;

    if (parentResult.length === 0) {
      return res.status(404).json({ error: "Parent not found" });
    }

    const storedHashedPassword = parentResult[0].password;

    const isPasswordValid = await bcrypt.compare(currentPassword, storedHashedPassword);

    if (!isPasswordValid) {
      return res.status(401).json({ error: "Current password is incorrect" });
    }

    const newHashedPassword = await bcrypt.hash(newPassword, 10);

    await sql`
      UPDATE "Parent" 
      SET password = ${newHashedPassword}
      WHERE parentid = ${parentId};
    `;

    return res.json({ message: "Password changed successfully" });

  } catch (err) {
    return res.status(500).json({
      error: "Failed to change password",
      details: err.message,
    });
  }
};

// 🟢 NEW: Change Child Password
export const changeChildPassword = async (req, res) => {
  try {
    const { childId } = req.params;
    const { newPassword } = req.body;

    if (!newPassword) {
      return res.status(400).json({ error: "New password is required" });
    }

    // التحقق من وجود الطفل
    const childResult = await sql`
      SELECT childid FROM "Child" WHERE childid = ${childId};
    `;

    if (childResult.length === 0) {
      return res.status(404).json({ error: "Child not found" });
    }

    // 🔐 تشفير كلمة المرور الجديدة
    const saltRounds = 10;
    const newHashedPassword = await bcrypt.hash(newPassword, saltRounds);

    // تحديث كلمة المرور المشفرة
    await sql`
      UPDATE "Child" 
      SET password = ${newHashedPassword}
      WHERE childid = ${childId};
    `;

    return res.json({ message: "Child password changed successfully" });

  } catch (err) {
    console.error("❌ Error changing child password:", err);
    return res.status(500).json({
      error: "Failed to change child password",
      details: err.message,
    });
  }
};