// server/controllers/rewardController.js
import { sql } from "../config/db.js";

// 1. إنشاء مكافأة جديدة (للوالد)
export const createReward = async (req, res) => {
  const { parentId, rewardName, rewardDescription, requiredKeys } = req.body;
  try {
    const newReward = await sql`
      INSERT INTO "Reward" (parentid, rewardname, rewarddescription, requiredkeys)
      VALUES (${parentId}, ${rewardName}, ${rewardDescription}, ${requiredKeys})
      RETURNING *
    `;
    res.status(201).json(newReward[0]);
  } catch (error) {
    console.error("Error creating reward:", error);
    res.status(500).json({ error: "Failed to create reward" });
  }
};

// 2. جلب مكافآت الوالد
export const getParentRewards = async (req, res) => {
  const { parentId } = req.params;
  try {
    const rewards = await sql`
      SELECT r.rewardid, r.rewardname, r.rewarddescription, r.requiredkeys, r.rewardstatus, c.firstname as redeemed_by_name
      FROM "Reward" r
      LEFT JOIN "Child" c ON r.redeemedby = c.childid
      WHERE r.parentid = ${parentId}
      ORDER BY r.rewardid DESC
    `;
    res.status(200).json(rewards);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch rewards" });
  }
};

// 3. جلب مكافآت الطفل + رصيد مفاتيحه الحالي
export const getChildRewardsData = async (req, res) => {
  const { childId } = req.params;
  try {
    // جلب بيانات الطفل (لمعرفة parentid ورصيد المفاتيح)
    const childData = await sql`SELECT parentid, rewardkeys FROM "Child" WHERE childid = ${childId}`;
    if (childData.length === 0) return res.status(404).json({ error: "Child not found" });
    
    const parentId = childData[0].parentid;
    const myKeys = childData[0].rewardkeys || 0;

    // جلب المكافآت المتاحة للجميع، والمكافآت التي اشتراها هذا الطفل تحديداً
    const rewards = await sql`
      SELECT rewardid, rewardname, rewarddescription, requiredkeys, rewardstatus
      FROM "Reward"
      WHERE parentid = ${parentId} 
      AND (rewardstatus = 'Available' OR redeemedby = ${childId})
      ORDER BY rewardid DESC
    `;

    res.status(200).json({ myKeys, rewards });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch child rewards data" });
  }
};

// 4. تعديل المكافأة
export const updateReward = async (req, res) => {
  const { rewardId } = req.params;
  const { rewardName, rewardDescription, requiredKeys } = req.body;
  try {
    const updated = await sql`
      UPDATE "Reward"
      SET rewardname = ${rewardName}, rewarddescription = ${rewardDescription}, requiredkeys = ${requiredKeys}
      WHERE rewardid = ${rewardId} AND rewardstatus = 'Available'
      RETURNING *
    `;
    res.status(200).json(updated[0]);
  } catch (error) {
    res.status(500).json({ error: "Failed to update reward" });
  }
};

// 5. حذف المكافأة
export const deleteReward = async (req, res) => {
  const { rewardId } = req.params;
  try {
    await sql`DELETE FROM "Reward" WHERE rewardid = ${rewardId}`;
    res.status(200).json({ message: "Reward deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to delete reward" });
  }
};

// 6. الطفل يقوم بشراء المكافأة (Redeem)
export const redeemReward = async (req, res) => {
  const { childId, rewardId } = req.body;

  try {
    // أ) التحقق من وجود المكافأة وحالتها
    const rewardCheck = await sql`SELECT * FROM "Reward" WHERE rewardid = ${rewardId}`;
    if (rewardCheck.length === 0) return res.status(404).json({ error: "Reward not found" });
    
    const reward = rewardCheck[0];
    if (reward.rewardstatus !== 'Available') return res.status(400).json({ error: "Reward is already redeemed" });

    // ب) التحقق من رصيد الطفل
    const childCheck = await sql`SELECT parentid, rewardkeys, firstname FROM "Child" WHERE childid = ${childId}`;
    const child = childCheck[0];
    
    if (child.rewardkeys < reward.requiredkeys) {
      return res.status(400).json({ error: "Not enough keys" });
    }

    // ج) تنفيذ العملية (خصم المفاتيح + تغيير حالة المكافأة)
    await sql`UPDATE "Child" SET rewardkeys = rewardkeys - ${reward.requiredkeys} WHERE childid = ${childId}`;
    await sql`UPDATE "Reward" SET rewardstatus = 'Redeemed', redeemedby = ${childId} WHERE rewardid = ${rewardId}`;

    // د) إرسال إشعار للوالد
    const message = `Your child ${child.firstname} has redeemed the reward: ${reward.rewardname}. Please fulfill it directly!`;
    await sql`
      INSERT INTO "Notification" (parentid, childid, type, message, isread, createdat)
      VALUES (${child.parentid}, ${childId}, 'REWARD_REDEEMED', ${message}, FALSE, CURRENT_TIMESTAMP)
    `;

    res.status(200).json({ message: "Reward redeemed successfully!" });
  } catch (error) {
    console.error("Redeem error:", error);
    res.status(500).json({ error: "Failed to redeem reward" });
  }
};