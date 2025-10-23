const express = require("express");
const router = express.Router();
const { checkUser, registerParent, loginParent, loginChild } = require("../controllers/authController");

router.post("/check-user", checkUser);
router.post("/register-parent", registerParent);
router.post("/login-parent", loginParent);
router.post("/login-child", loginChild);

module.exports = router;
