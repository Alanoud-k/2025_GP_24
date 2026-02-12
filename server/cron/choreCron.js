import cron from "node-cron";
import { sql } from "../config/db.js";

export const startChoreCron = () => {
  // التشغيل كل دقيقة للتحقق من المواعيد
  // الرمز "* * * * *" يعني كل دقيقة
  cron.schedule("* * * * *", async () => {
    
    // 1. معرفة الوقت واليوم الحاليين بتوقيت السعودية
    const now = new Date();
    // ضبط الوقت ليتناسب مع الرياض (إذا كان السيرفر بتوقيت UTC)
    // أو نعتمد على توقيت السيرفر إذا كان مضبوطاً
    
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const currentDay = days[now.getDay()]; // e.g., "Monday"
    
    // تنسيق الوقت الحالي بصيغة HH:mm (مثلاً 14:30)
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const currentTime = `${hours}:${minutes}`;

    console.log(`🔎 Checking chores for: ${currentDay} at ${currentTime}`);

    try {
      // 2. البحث عن المهام الأسبوعية التي تطابق هذا الوقت واليوم
      // وتكون حالتها "Completed" (أي أنها منتهية ونريد تفعيلها مجدداً للأسبوع الجديد)
      const choresToReset = await sql`
        UPDATE "Chore"
        SET "chorestatus" = 'Pending'
        WHERE "choretype" = 'Weekly'
          AND "assigned_day" = ${currentDay}
          AND "assigned_time" = ${currentTime}
          AND "chorestatus" = 'Completed' -- فقط نعيد تفعيل المنتهية
        RETURNING "choreid", "chorename"
      `;

      if (choresToReset.length > 0) {
        console.log(`🔄 Reactivated ${choresToReset.length} weekly chores:`, choresToReset);
        // هنا يمكنك إضافة كود لإرسال إشعار للطفل بأن المهمة تجددت
      }

    } catch (err) {
      console.error("❌ Error in Chore Cron:", err);
    }
  }, {
    timezone: "Asia/Riyadh"
  });
};