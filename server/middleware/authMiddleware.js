import jwt from "jsonwebtoken";

export function protect(req, res, next) {
  let token;

  // Expect: Authorization: Bearer xxxxx
  if (req.headers.authorization && req.headers.authorization.startsWith("Bearer")) {
    token = req.headers.authorization.split(" ")[1];
  }

  if (!token) {
    return res.status(401).json({ error: "Not authorized, missing token" });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id, role, iat, exp }
    next();
  } catch (err) {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}

app.use((req, res, next) => {
  console.log("🛰 Incoming Authorization:", req.headers.authorization);
  next();
});
