const { sql } = require("../config/db");

// 🟢 Get Parent Info by ID
exports.getParentInfo = async (req, res) => {
  try {
    const { parentId } = req.params;

    console.log(`📡 Fetching parent info for ID: ${parentId}`);

    const result = await sql`
      SELECT p.firstname, p.lastname, p.phoneno, p.nationalid, w.walletbalance
      FROM "Parent" p
      JOIN "Wallet" w ON p.parentid = w.parentid
      WHERE p.parentid = ${parentId};
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: "Parent not found" });
    }

    const parent = result[0];
    res.json({
      firstName: parent.firstname,
      lastName: parent.lastname,
      phoneNo: parent.phoneno,
      walletBalance: parent.walletbalance,
    });

  } catch (err) {
    console.error("❌ Error fetching parent info:", err);
    res.status(500).json({ error: "Failed to fetch parent info", details: err.message });
  }
};
