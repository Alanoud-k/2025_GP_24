import { sql } from "../config/db.js";

// جلب مهام طفل محدد
export const getChildChores = async (req, res) => {
  const { childId } = req.params;
  
  console.log(`🔍 Request received for Child ID: ${childId}`); // 1. تأكيد وصول الطلب

  try {
    const chores = await sql`
      SELECT * FROM "Chore"
      WHERE "childid" = ${childId}
      ORDER BY "choreid" DESC
    `;

    // 2. طباعة البيانات الخام القادمة من الداتابيس لنرى أسماء الأعمدة
    console.log("🔥 Data from Database:", chores); 

    if (chores.length > 0) {
        console.log("📋 Sample Row Keys:", Object.keys(chores[0])); // لنرى أسماء الأعمدة بالضبط
    }

    // 3. التحويل (مع حماية ضد الأخطاء)
    const formattedChores = chores.map(chore => {
      // طباعة إذا كان هناك حقل مفقود
      if (!chore.choreid) console.warn("⚠️ Warning: choreid is missing for a row!");

      return {
        _id: chore.choreid ? chore.choreid.toString() : "0", // حماية من الانهيار
        title: chore.chorename || "No Title",
        description: chore.choredescription || "",
        keys: chore.rewardkeys || 0,
        status: chore.chorestatus || "Pending",
        childId: chore.childid
      };
    });

    console.log("✅ Sending Response:", formattedChores); // 4. تأكيد البيانات المرسلة
    return res.json(formattedChores);

  } catch (err) {
    console.error("❌ SERVER ERROR inside getChildChores:", err); // سيطبع لكِ الخطأ الحقيقي بالأحمر
    return res.status(500).json({ 
        error: "Failed to fetch chores", 
        details: err.message // إرسال تفاصيل الخطأ للتطبيق
    });
  }
};

// ... (دالة getParentChores يمكن أن تبقى كما هي أو تطبق عليها نفس المنطق)
export const getParentChores = async (req, res) => {
    // ... نفس الكود السابق
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