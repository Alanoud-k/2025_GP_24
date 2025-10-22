const express = require("express");
const { checkUser, registerParent } = require("../controllers/authController");

const router = express.Router();

router.post("/check-user", checkUser);
router.post("/register-parent", registerParent);

module.exports = router;
