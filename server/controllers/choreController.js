import { sql } from "../config/db.js";
import { createNotification } from "./notificationController.js";

// 1. جلب مهام طفل محدد
export const getChildChores = async (req, res) => {
  const { childId } = req.params;
  try {
    const chores = await sql`
      SELECT * FROM "Chore"
      WHERE "childid" = ${childId}
      ORDER BY "choreid" DESC
    `;
    const formatted = chores.map(chore => ({
      _id: chore.choreid.toString(),
      title: chore.chorename,
      description: chore.choredescription,
      keys: chore.rewardkeys,
      status: chore.chorestatus,
      childId: chore.childid,
      type: chore.choretype || 'One-time',
      proofUrl: chore.choreproofurl,
      rejectionReason: chore.rejection_reason 
    }));
    return res.json(formatted);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

// 2. جلب مهام الأب العامة
export const getParentChores = async (req, res) => {
  const { parentId } = req.params;
  try {
    const chores = await sql`
      SELECT c.*, ch."firstname" as "childName"
      FROM "Chore" c
      JOIN "Child" ch ON c."childid" = ch."childid"
      WHERE c."parentid" = ${parentId}
      ORDER BY c."choreid" DESC
    `;
    const formatted = chores.map(chore => ({
      _id: chore.choreid.toString(),
      title: chore.chorename,
      description: chore.choredescription,
      keys: chore.rewardkeys,
      status: chore.chorestatus,
      childId: chore.childid, // ✅ حل مشكلة 2: إرسال آيدي الطفل الصحيح لفرز البطاقات
      childName: chore.childName,
      type: chore.choretype || 'One-time',
      proofUrl: chore.choreproofurl,
      rejectionReason: chore.rejection_reason 
    }));
    return res.json(formatted);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

// 3. إضافة مهمة جديدة
export const createChore = async (req, res) => {
  const { title, description, keys, childId, parentId, type, assignedDay, assignedTime } = req.body; 
  try {
    if (!title || !keys || !childId || !parentId) return res.status(400).json({ error: "Missing fields" });

    const newChore = await sql`
      INSERT INTO "Chore" ("chorename", "choredescription", "rewardkeys", "chorestatus", "childid", "parentid", "choretype", "assigned_day", "assigned_time")
      VALUES (${title}, ${description || ''}, ${keys}, 'Pending', ${childId}, ${parentId}, ${type || 'One-time'}, ${assignedDay || null}, ${assignedTime || null})
      RETURNING *
    `;

    await createNotification(parentId, childId, 'CHORE_ASSIGNED', `New chore assigned: ${title}`, null, newChore[0].choreid);

    return res.json({ message: "Chore created", chore: newChore[0] });
  } catch (err) {
    return res.status(500).json({ error: "Failed to create chore", details: err.message });
  }
};

// 4. تحديث الحالة
export const updateChoreStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  try {
    const updatedResult = await sql`
      UPDATE "Chore" 
      SET "chorestatus" = ${status} 
      WHERE "choreid" = ${id} 
      RETURNING *
    `;

    if (updatedResult.length === 0) return res.status(404).json({ error: "Chore not found" });
    const chore = updatedResult[0];

    if (status === 'Completed') {
      await sql`
        UPDATE "Child"
        SET "rewardkeys" = COALESCE("rewardkeys", 0) + ${chore.rewardkeys}
        WHERE "childid" = ${chore.childid}
      `;
    }

    return res.json(chore);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

// 5. تعديل التفاصيل
export const updateChoreDetails = async (req, res) => {
  const { id } = req.params; 
  const { title, description, keys } = req.body;

  try {
    const updated = await sql`
      UPDATE "Chore" SET "chorename" = ${title}, "choredescription" = ${description}, "rewardkeys" = ${keys}
      WHERE "choreid" = ${id} RETURNING *
    `;
    if (updated.length === 0) return res.status(404).json({ error: "Chore not found" });
    return res.json(updated[0]);
  } catch (err) {
    return res.status(500).json({ error: "Failed to edit chore" });
  }
};

// 6. إنهاء المهمة ورفع الصورة 
export const completeChore = async (req, res) => {
  const { id } = req.params;
  if (!req.file) return res.status(400).json({ error: "Proof picture is required." });
  const proofUrl = req.file.path; 

  try {
    const updated = await sql`
      UPDATE "Chore" 
      SET 
        "chorestatus" = 'Submitted', 
        "choreproofurl" = ${proofUrl},
        "rejection_reason" = NULL -- ✅ مسح سبب الرفض لأن الطفل أرسل إثبات جديد
      WHERE "choreid" = ${id} 
      RETURNING *
    `;

    if (updated.length === 0) return res.status(404).json({ error: "Chore not found" });
    const chore = updated[0];

    const child = await sql`SELECT firstname FROM "Child" WHERE childid = ${chore.childid}`;
    const childName = child[0]?.firstname || "Your child";

    await createNotification(chore.parentid, chore.childid, 'CHORE_COMPLETED', `${childName} submitted proof for: ${chore.chorename}`, null, chore.choreid);

    return res.json({ message: "Chore submitted", chore: chore });
  } catch (err) {
    return res.status(500).json({ error: "Failed to submit chore" });
  }
};

// 7. رفض المهمة وإعادتها للطفل
export const rejectChore = async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  try {
    const updated = await sql`
      UPDATE "Chore" 
      SET "chorestatus" = 'Pending', "choreproofurl" = NULL, "rejection_reason" = ${reason}
      WHERE "choreid" = ${id} 
      RETURNING *
    `;

    if (updated.length === 0) return res.status(404).json({ error: "Chore not found" });
    const chore = updated[0];

    await createNotification(chore.parentid, chore.childid, 'CHORE_REJECTED', `Chore rejected: ${chore.chorename}`, null, chore.choreid);

    return res.json({ message: "Chore rejected", chore });
  } catch (err) {
    return res.status(500).json({ error: "Failed to reject chore" });
  }
};

// 8. حذف المهمة 
export const deleteChore = async (req, res) => {
  const { id } = req.params;

  try {
    const deleted = await sql`
      DELETE FROM "Chore" 
      WHERE "choreid" = ${id} 
      RETURNING *
    `;

    if (deleted.length === 0) {
      return res.status(404).json({ error: "Chore not found" });
    }

    return res.json({ message: "Chore deleted successfully", chore: deleted[0] });
  } catch (err) {
    console.error("❌ Error deleting chore:", err);
    return res.status(500).json({ error: "Failed to delete chore" });
  }
};