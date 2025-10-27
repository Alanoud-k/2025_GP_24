
const express = require("express");
const router = express.Router();
const { checkUser, registerParent, loginParent, loginChild, logout } = require("../controllers/authController");
const { getChildrenByParent, registerChild } = require("../controllers/childController");
const authController = require("../controllers/authController");


router.post("/check-user", checkUser);
router.post("/register-parent", registerParent);
router.post("/login-parent", loginParent);
router.post("/login-child", loginChild);
router.get("/child/:parentId", getChildrenByParent);
router.post("/child/register", registerChild);
router.get("/parent/:parentId", authController.getParentInfo);
router.post("/forgot-password", authController.forgotPassword);
router.post("/logout", logout);

module.exports = router;
