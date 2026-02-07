import { sql } from "../config/db.js";

/* ============================================================
   1. GET CHILD CHORES (مع سجلات تتبع الأخطاء Debugging)
   Route: GET /api/chores/child/:childId
============================================================ */
export const getChildChores = async (req, res) => {
  const { childId } = req.params;
  
  console.log(`🔍 Request received for Child ID: ${childId}`); 

  try {
    const chores = await sql`
      SELECT * FROM "Chore"
      WHERE "childid" = ${childId}
      ORDER BY "choreid" DESC
    `;

    console.log("🔥 Data from Database:", chores); 

    const formattedChores = chores.map(chore => ({
      _id: chore.choreid.toString(),
      title: chore.chorename || "No Title",
      description: chore.choredescription || "",
      keys: chore.rewardkeys || 0,
      status: chore.chorestatus || "Pending",
      childId: chore.childid
    }));

    return res.json(formattedChores);

  } catch (err) {
    console.error("❌ SERVER ERROR inside getChildChores:", err);
    return res.status(500).json({ error: "Failed to fetch chores", details: err.message });
  }
};

/* ============================================================
   2. GET PARENT CHORES
   Route: GET /api/chores/parent/:parentId
============================================================ */
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

    const formattedChores = chores.map(chore => ({
      _id: chore.choreid.toString(),
      title: chore.chorename,
      description: chore.choredescription,
      keys: chore.rewardkeys,
      status: chore.chorestatus,
      childId: chore.childid,
      childName: chore.childName
    }));

    return res.json(formattedChores);
  } catch (err) {
    console.error("Error fetching parent chores:", err);
    return res.status(500).json({ error: "Failed to fetch chores" });
  }
};

/* ============================================================
   3. CREATE CHORE (إضافة مهمة جديدة)
   Route: POST /api/chores/create
============================================================ */
export const createChore = async (req, res) => {
  // نستقبل البيانات بالأسماء التي يرسلها تطبيق فلاتر
  const { title, description, keys, childId, parentId } = req.body;

  try {
    // التحقق من البيانات المطلوبة
    if (!title || !keys || !childId || !parentId) {
        return res.status(400).json({ error: "Missing required fields (title, keys, childId, parentId)" });
    }

    // الإدخال في قاعدة البيانات (لاحظي استخدام الأسماء الصحيحة لجدول Neon)
    const newChore = await sql`
      INSERT INTO "Chore" (
        "chorename", 
        "choredescription", 
        "rewardkeys", 
        "chorestatus", 
        "childid", 
        "parentid"
      )
      VALUES (
        ${title}, 
        ${description || ''}, 
        ${keys}, 
        'Pending', 
        ${childId}, 
        ${parentId}
      )
      RETURNING *
    `;

    return res.json({ message: "Chore created successfully", chore: newChore[0] });

  } catch (err) {
    console.error("❌ Error creating chore:", err);
    return res.status(500).json({ error: "Failed to create chore", details: err.message });
  }
};

/* ============================================================
   4. UPDATE CHORE STATUS (تحديث الحالة)
   Route: PATCH /api/chores/:id/status
============================================================ */
export const updateChoreStatus = async (req, res) => {
  const { id } = req.params; // choreId
  const { status } = req.body;

  try {
    // تحديث عمود chorestatus في الجدول
    const updated = await sql`
      UPDATE "Chore"
      SET "chorestatus" = ${status}
      WHERE "choreid" = ${id}
      RETURNING *
    `;

    if (updated.length === 0) {
      return res.status(404).json({ error: "Chore not found" });
    }

    return res.json(updated[0]);
  } catch (err) {
    console.error("Error updating chore:", err);
    return res.status(500).json({ error: "Failed to update chore" });
  }
};