// import { sql } from "../config/db.js";
// import { createNotification } from "./notificationController.js"; 

// // 1. جلب مهام طفل محدد
// export const getChildChores = async (req, res) => {
//   const { childId } = req.params;
//   try {
//     const chores = await sql`
//       SELECT * FROM "Chore"
//       WHERE "childid" = ${childId}
//       ORDER BY "choreid" DESC
//     `;
//     const formatted = chores.map(chore => ({
//       _id: chore.choreid.toString(),
//       title: chore.chorename,
//       description: chore.choredescription,
//       keys: chore.rewardkeys,
//       status: chore.chorestatus,
//       childId: chore.childid, // 👈 تم إضافة الفاصلة هنا
//       type: chore.choretype || 'One-time' // ✅ الآن سيعمل بدون مشاكل
//     }));
//     return res.json(formatted);
//   } catch (err) {
//     return res.status(500).json({ error: err.message });
//   }
// };

// // 2. جلب مهام الأب العامة
// export const getParentChores = async (req, res) => {
//   const { parentId } = req.params;
//   try {
//     const chores = await sql`
//       SELECT c.*, ch."firstname" as "childName"
//       FROM "Chore" c
//       JOIN "Child" ch ON c."childid" = ch."childid"
//       WHERE c."parentid" = ${parentId}
//       ORDER BY c."choreid" DESC
//     `;
//     const formatted = chores.map(chore => ({
//       _id: chore.choreid.toString(),
//       title: chore.chorename,
//       description: chore.choredescription, // أضفت الوصف أيضاً للاحتياط
//       keys: chore.rewardkeys,
//       status: chore.chorestatus,
//       childName: chore.childName,
//       type: chore.choretype || 'One-time' // ✅ أضفت النوع هنا أيضاً لتظهر العلامة للأب
//     }));
//     return res.json(formatted);
//   } catch (err) {
//     return res.status(500).json({ error: err.message });
//   }
// };

// // ... (الاستيرادات)

// // 3. إضافة مهمة جديدة (Create)
// export const createChore = async (req, res) => {
//   // نستقبل الحقول الجديدة هنا 👇
//   const { title, description, keys, childId, parentId, type, assignedDay, assignedTime } = req.body; 

//   try {
//     if (!title || !keys || !childId || !parentId) {
//         return res.status(400).json({ error: "Missing required fields" });
//     }

//     const newChore = await sql`
//       INSERT INTO "Chore" (
//         "chorename", 
//         "choredescription", 
//         "rewardkeys", 
//         "chorestatus", 
//         "childid", 
//         "parentid",
//         "choretype",
//         "assigned_day",  -- 👈
//         "assigned_time"  -- 👈
//       )
//       VALUES (
//         ${title}, 
//         ${description || ''}, 
//         ${keys}, 
//         'Pending', 
//         ${childId}, 
//         ${parentId},
//         ${type || 'One-time'},
//         ${assignedDay || null}, -- 👈 نخزن اليوم أو null
//         ${assignedTime || null}  -- 👈 نخزن الوقت أو null
//       )
//       RETURNING *
//     `;

//     return res.json({ message: "Chore created", chore: newChore[0] });

//   } catch (err) {
//     console.error("❌ Error creating chore:", err);
//     return res.status(500).json({ error: "Failed to create chore", details: err.message });
//   }
// };

// // ... (باقي الدوال)

// // 4. تحديث الحالة (Approve/Update)
// export const updateChoreStatus = async (req, res) => {
//   const { id } = req.params;
//   const { status } = req.body;
//   try {
//     const updated = await sql`
//       UPDATE "Chore" SET "chorestatus" = ${status} WHERE "choreid" = ${id} RETURNING *
//     `;
//     return res.json(updated[0]);
//   } catch (err) {
//     return res.status(500).json({ error: err.message });
//   }
// };

// // 5. تعديل تفاصيل المهمة
// export const updateChoreDetails = async (req, res) => {
//   const { id } = req.params; 
//   const { title, description, keys } = req.body;

//   try {
//     const updated = await sql`
//       UPDATE "Chore"
//       SET 
//         "chorename" = ${title},
//         "choredescription" = ${description},
//         "rewardkeys" = ${keys}
//       WHERE "choreid" = ${id}
//       RETURNING *
//     `;

//     if (updated.length === 0) {
//       return res.status(404).json({ error: "Chore not found" });
//     }

//     return res.json(updated[0]);
//   } catch (err) {
//     console.error("❌ Error editing chore:", err);
//     return res.status(500).json({ error: "Failed to edit chore" });
//   }
// };

// // // 6. الطفل يكمل المهمة (طلب موافقة)
// // export const completeChore = async (req, res) => {
// //   const { id } = req.params;
  
// //   try {
// //     // نحدث الحالة فقط إذا كانت Pending
// //     const updated = await sql`
// //       UPDATE "Chore" 
// //       SET "chorestatus" = 'Waiting Approval' 
// //       WHERE "choreid" = ${id} 
// //       RETURNING *
// //     `;

// //     if (updated.length === 0) {
// //       return res.status(404).json({ error: "Chore not found" });
// //     }

// //     // هنا يمكن إضافة كود لإرسال إشعار للأب (اختياري)
// //     // await createNotificationForParent(...)

// //     return res.json({ message: "Chore sent for approval", chore: updated[0] });
// //   } catch (err) {
// //     console.error("❌ Error completing chore:", err);
// //     return res.status(500).json({ error: "Failed to complete chore" });
// //   }
// // };

// // 6. الطفل يكمل المهمة (طلب موافقة)
// export const completeChore = async (req, res) => {
//   const { id } = req.params;
  
//   // التحقق من وجود الملف
//   if (!req.file) {
//     return res.status(400).json({ error: "Proof picture is required." });
//   }

//   // ✅ التغيير هنا: Cloudinary يعطينا الرابط جاهزاً في path
//   const proofUrl = req.file.path; 

//   try {
//     const updated = await sql`
//       UPDATE "Chore" 
//       SET 
//         "chorestatus" = 'Submitted', 
//         "choreproofurl" = ${proofUrl} -- 👈 نخزن الرابط الكامل مباشرة
//       WHERE "choreid" = ${id} 
//       RETURNING *
//     `;

//     if (updated.length === 0) {
//       return res.status(404).json({ error: "Chore not found" });
//     }

//     const chore = updated[0];

//     // ثانياً: نجلب اسم الطفل لإدراجه في الرسالة (اختياري للتحسين)
//     const child = await sql`SELECT firstname FROM "Child" WHERE childid = ${chore.childid}`;
//     const childName = child[0]?.firstname || "Your child";

//     // 👇 3. إرسال الإشعار للأب
//     await createNotification(
//       chore.parentid,         // معرف الأب (موجود في جدول Chore)
//       chore.childid,          // معرف الطفل
//       'CHORE_COMPLETED',      // نوع الإشعار (تأكدي من توحيد المسميات)
//       `${childName} completed the chore: ${chore.chorename}`, // نص الرسالة
//       null,                   // لا يوجد MoneyRequest
//       chore.choreid           // معرف المهمة
//     );

// return res.json({ message: "Chore submitted", chore: chore });
//   } catch (err) {
//     console.error("❌ Error completing chore:", err);
//     return res.status(500).json({ error: "Failed to complete chore" });
//   }
// };


import { sql } from "../config/db.js";
import { createNotification } from "./notificationController.js"; // تأكدي من وجودها

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
      proofUrl: chore.choreproofurl // 👈 إرجاع رابط الصورة للفرونت إند
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
      childName: chore.childName,
      type: chore.choretype || 'One-time',
      proofUrl: chore.choreproofurl // 👈 إرجاع رابط الصورة للأب
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
        "choretype",
        "assigned_day",
        "assigned_time"
      )
      VALUES (
        ${title}, 
        ${description || ''}, 
        ${keys}, 
        'Pending', 
        ${childId}, 
        ${parentId},
        ${type || 'One-time'},
        ${assignedDay || null},
        ${assignedTime || null}
      )
      RETURNING *
    `;

    return res.json({ message: "Chore created", chore: newChore[0] });

  } catch (err) {
    console.error("❌ Error creating chore:", err);
    return res.status(500).json({ error: "Failed to create chore", details: err.message });
  }
};

// 4. تحديث الحالة
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

// 5. تعديل التفاصيل
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
    return res.status(500).json({ error: "Failed to edit chore" });
  }
};

// 6. إنهاء المهمة ورفع الصورة (Cloudinary)
export const completeChore = async (req, res) => {
  const { id } = req.params;
  
  // التحقق من وصول الملف
  if (!req.file) {
    return res.status(400).json({ error: "Proof picture is required." });
  }

  // ✅ Cloudinary يعيد الرابط جاهزاً في path
  const proofUrl = req.file.path; 

  try {
    // ⚠️ تأكدي أن 'Submitted' مضافة في الـ ENUM في قاعدة البيانات
    // إذا لم تكن موجودة استخدمي 'Pending' مؤقتاً
    const updated = await sql`
      UPDATE "Chore" 
      SET 
        "chorestatus" = 'Submitted', 
        "choreproofurl" = ${proofUrl}
      WHERE "choreid" = ${id} 
      RETURNING *
    `;

    if (updated.length === 0) {
      return res.status(404).json({ error: "Chore not found" });
    }

    const chore = updated[0];

    // جلب اسم الطفل للإشعار
    const child = await sql`SELECT firstname FROM "Child" WHERE childid = ${chore.childid}`;
    const childName = child[0]?.firstname || "Your child";

    // إرسال الإشعار للأب
    await createNotification(
      chore.parentid, 
      chore.childid, 
      'CHORE_COMPLETED',
      `${childName} submitted proof for: ${chore.chorename}`,
      null,
      chore.choreid
    );

    return res.json({ message: "Chore submitted", chore: chore });
  } catch (err) {
    console.error("❌ Error completing chore:", err);
    return res.status(500).json({ error: "Failed to submit chore" });
  }
};