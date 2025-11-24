// server/routes/parentRoutes.js

import express from "express";
import { sql } from "../config/db.js";
import { getParentCard, saveParentCard } from "../controllers/parentCardController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

/* ---------------------------------------------------------
   GET /api/parent/:parentId
   Returns parent info + wallet balance
--------------------------------------------------------- */
router.get("/parent/:parentId", async (req, res) => {
  const parentId = Number(req.params.parentId);

  if (!parentId) {
    return res.status(400).json({ message: "Invalid parentId" });
  }

  try {
    const rows = await sql`
      SELECT
        p."parentid",
        p."firstname",
        COALESCE(a."balance", 0) AS walletbalance
      FROM "Parent" p
      LEFT JOIN "Wallet" w
        ON w."parentid" = p."parentid"
      LEFT JOIN "Account" a
        ON a."walletid" = w."walletid"
       AND a."accounttype" = 'ParentAccount'
      WHERE p."parentid" = ${parentId}
      LIMIT 1
    `;

    if (!rows.length) {
      return res.status(404).json({ message: "Parent not found" });
    }

    return res.status(200).json(rows[0]);
  } catch (err) {
    console.error("getParent error:", err);
    return res.status(500).json({ message: "Server error" });
  }
});

/* ---------------------------------------------------------
   Parent Card Endpoints
--------------------------------------------------------- */

// GET saved card
router.get("/parent/:parentId/card", protect, getParentCard);

// POST save/replace card
router.post("/parent/:parentId/card", protect, saveParentCard);

export default router;
