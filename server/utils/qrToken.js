// server/utils/qrToken.js
import crypto from "crypto";

export function generateToken() {
  // URL-safe token
  return crypto.randomBytes(24).toString("hex");
}

export function buildQrString(token) {
  // Your Flutter expects: HASSALA_PAY:1:<token>
  return `HASSALA_PAY:1:${token}`;
}