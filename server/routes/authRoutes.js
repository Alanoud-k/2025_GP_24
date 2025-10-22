const express = require("express");
const router = express.Router();
const { checkUser, registerParent, loginParent } = require("../controllers/authController");

router.post("/check-user", checkUser);
router.post("/register-parent", registerParent);
router.post("/login-parent", loginParent);

module.exports = router;
