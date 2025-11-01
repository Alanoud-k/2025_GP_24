
const express = require("express");
const router = express.Router();
const { checkUser, registerParent, getNameByPhone, loginParent, loginChild, logout } = require("../controllers/authController");
const { getChildrenByParent, registerChild } = require("../controllers/childController");
const authController = require("../controllers/authController");


router.post("/check-user", checkUser);
router.post("/register-parent", registerParent);
router.get("/name/:phoneNo", authController.getNameByPhone);
router.post("/login-parent", loginParent);
router.post("/login-child", loginChild);
router.get("/child/:parentId", getChildrenByParent);
router.post("/child/register", registerChild);
router.get("/parent/:parentId", authController.getParentInfo);
router.get("/child/info/:childId", authController.getChildInfo);
router.post("/forgot-password", authController.forgotPassword);
router.post("/logout", logout);

module.exports = router;
