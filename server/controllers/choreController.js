import { sql } from "../config/db.js";

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
      childId: chore.childid, // 👈 تم إضافة الفاصلة هنا
      type: chore.choretype || 'One-time' // ✅ الآن سيعمل بدون مشاكل
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
      description: chore.choredescription, // أضفت الوصف أيضاً للاحتياط
      keys: chore.rewardkeys,
      status: chore.chorestatus,
      childName: chore.childName,
      type: chore.choretype || 'One-time' // ✅ أضفت النوع هنا أيضاً لتظهر العلامة للأب
    }));
    return res.json(formatted);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

// 3. إضافة مهمة جديدة (Create)
export const createChore = async (req, res) => {
  const { title, description, keys, childId, parentId, type } = req.body; 

  try {
    if (!title || !keys || !childId || !parentId) {
        return res.status(400).json({ error: "Missing required fields" });
    }

    const newChore = await sql`
      INSERT INTO "Chore" (
        "chorename", 
        "choredescription", 
        "rewardkeys", 
        "chorestatus", 
        "childid", 
        "parentid",
        "choretype"
      )
      VALUES (
        ${title}, 
        ${description || ''}, 
        ${keys}, 
        'Pending', 
        ${childId}, 
        ${parentId},
        ${type || 'One-time'}
      )
      RETURNING *
    `;

    return res.json({ message: "Chore created", chore: newChore[0] });

  } catch (err) {
    console.error("❌ Error creating chore:", err);
    return res.status(500).json({ error: "Failed to create chore", details: err.message });
  }
};

// 4. تحديث الحالة (Approve/Update)
export const updateChoreStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  try {
    const updated = await sql`
      UPDATE "Chore" SET "chorestatus" = ${status} WHERE "choreid" = ${id} RETURNING *
    `;
    return res.json(updated[0]);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

// 5. تعديل تفاصيل المهمة
export const updateChoreDetails = async (req, res) => {
  const { id } = req.params; 
  const { title, description, keys } = req.body;

  try {
    const updated = await sql`
      UPDATE "Chore"
      SET 
        "chorename" = ${title},
        "choredescription" = ${description},
        "rewardkeys" = ${keys}
      WHERE "choreid" = ${id}
      RETURNING *
    `;

    if (updated.length === 0) {
      return res.status(404).json({ error: "Chore not found" });
    }

    return res.json(updated[0]);
  } catch (err) {
    console.error("❌ Error editing chore:", err);
    return res.status(500).json({ error: "Failed to edit chore" });
  }
};