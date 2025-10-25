const express = require("express");
const router = express.Router();
const { checkUser, registerParent, loginParent, loginChild } = require("../controllers/authController");
const { getChildrenByParent, registerChild } = require("../controllers/childController");

router.post("/check-user", checkUser);
router.post("/register-parent", registerParent);
router.post("/login-parent", loginParent);
router.post("/login-child", loginChild);
router.get("/child/:parentId", getChildrenByParent);
router.post("/child/register", registerChild);

module.exports = router;
