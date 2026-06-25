import express from "express";
import jwt from "jsonwebtoken";
import crypto from "crypto";
import bcrypt from "bcrypt";
import mysql from "mysql2/promise";

const router = express.Router();

const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "smart_health_desk",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

const ACCESS_TOKEN_SECRET = process.env.ACCESS_TOKEN_SECRET || "access_secret";
const REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET || "refresh_secret";
const ACCESS_TOKEN_EXPIRES_IN = "15m";
const REFRESH_TOKEN_EXPIRES_IN = "7d";

function signAccessToken(user) {
  return jwt.sign(
    { sub: user.id, role: user.role },
    ACCESS_TOKEN_SECRET,
    { expiresIn: ACCESS_TOKEN_EXPIRES_IN }
  );
}
function signRefreshToken(user, familyId) {
  // No heavy info in payload; include maybe user id and family
  return jwt.sign(
    { sub: user.id, family_id: familyId },
    REFRESH_TOKEN_SECRET,
    { expiresIn: REFRESH_TOKEN_EXPIRES_IN }
  );
}

router.post("/login", async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ message: "Email/password required" });

  const conn = await pool.getConnection();
  try {
    const [users] = await conn.execute(
      "SELECT id, role, password_hash FROM profiles WHERE email = ? LIMIT 1",
      [email]
    );
    if (!users?.length) return res.status(401).json({ message: "Invalid credentials" });

    const user = users[0];
    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) return res.status(401).json({ message: "Invalid credentials" });

    const familyId = crypto.randomUUID();
    const accessToken = signAccessToken(user);
    const refreshToken = signRefreshToken(user, familyId);

    // expires_at in DB for scanning stale tokens
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await conn.execute(
      `INSERT INTO refresh_tokens (id, user_id, token, family_id, is_used, expires_at, created_at)
       VALUES (UUID(), ?, ?, ?, false, ?, NOW())`,
      [user.id, refreshToken, familyId, expiresAt]
    );

    return res.json({ access_token: accessToken, refresh_token: refreshToken });
  } catch (err) {
    console.error("login error", err);
    return res.status(500).json({ message: "Server error" });
  } finally {
    conn.release();
  }
});

router.post("/refresh", async (req, res) => {
  const { refresh_token: incomingRefreshToken } = req.body;
  if (!incomingRefreshToken) return res.status(400).json({ message: "refresh_token required" });

  let payload;
  try {
    payload = jwt.verify(incomingRefreshToken, REFRESH_TOKEN_SECRET);
  } catch (err) {
    return res.status(401).json({ message: "Invalid refresh token" });
  }

  const conn = await pool.getConnection();
  try {
    const [rows] = await conn.execute(
      `SELECT id, user_id, family_id, is_used, expires_at
       FROM refresh_tokens
       WHERE token = ?`,
      [incomingRefreshToken]
    );

    if (!rows.length) return res.status(401).json({ message: "Refresh token not found" });

    const tokenRow = rows[0];
    const now = new Date();
    if (tokenRow.expires_at < now) {
      await conn.execute(`DELETE FROM refresh_tokens WHERE id = ?`, [tokenRow.id]);
      return res.status(401).json({ message: "Refresh token expired" });
    }

    // Theft detection: used token reuse
    if (tokenRow.is_used) {
      await conn.execute(
        `UPDATE refresh_tokens SET is_used = TRUE WHERE family_id = ?`,
        [tokenRow.family_id]
      );
      await conn.execute(
        `DELETE FROM refresh_tokens WHERE family_id = ?`,
        [tokenRow.family_id]
      );
      console.warn(
        `Refresh token theft detected for family_id=${tokenRow.family_id} user_id=${tokenRow.user_id}`
      );
      return res.status(403).json({ message: "Refresh token reuse detected, session locked" });
    }

    // Normal rotation: mark the old one used
    await conn.execute(
      `UPDATE refresh_tokens SET is_used = TRUE WHERE id = ?`,
      [tokenRow.id]
    );

    // Create new tokens in same family
    const [users] = await conn.execute(
      `SELECT id, role FROM profiles WHERE id = ? LIMIT 1`,
      [tokenRow.user_id]
    );
    if (!users.length) return res.status(401).json({ message: "User account not found" });

    const user = users[0];
    const newAccessToken = signAccessToken(user);
    const newRefreshToken = signRefreshToken(user, tokenRow.family_id);

    const newExpiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await conn.execute(
      `INSERT INTO refresh_tokens (id, user_id, token, family_id, is_used, expires_at, created_at)
       VALUES (UUID(), ?, ?, ?, false, ?, NOW())`,
      [user.id, newRefreshToken, tokenRow.family_id, newExpiresAt]
    );

    return res.json({ access_token: newAccessToken, refresh_token: newRefreshToken });
  } catch (err) {
    console.error("refresh error", err);
    return res.status(500).json({ message: "Server error" });
  } finally {
    conn.release();
  }
});

export default router;