// Authentication: register/login/me, password hashing, JWT (HS256).

import {
  createHmac,
  randomBytes,
  scryptSync,
  timingSafeEqual,
} from 'node:crypto';

import { db, nowIso } from './db.js';
import { emailTaken, json, stringField, unauthorized, validationError } from './errors.js';

/** Secret used to sign JWTs. Override with the JWT_SECRET env variable. */
export const jwtSecret = process.env.JWT_SECRET ?? 'dev-secret-change-me';

// ---------------------------------------------------------------------------
// Route handlers
// ---------------------------------------------------------------------------

/** POST /auth/register  {email, password, name} -> 201 {token, user} */
export function register(req, res) {
  const email = stringField(req.body, 'email');
  const password = stringField(req.body, 'password');
  const name = stringField(req.body, 'name');
  if (email === null || !email.includes('@')) {
    return validationError(res, 'A valid email is required');
  }
  if (password === null) return validationError(res, 'password is required');
  if (name === null) return validationError(res, 'name is required');

  const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
  if (existing !== undefined) return emailTaken(res);

  const { lastInsertRowid } = db
    .prepare(
      'INSERT INTO users (email, password_hash, name, created_at) ' +
        'VALUES (?, ?, ?, ?)',
    )
    .run(email, hashPassword(password), name, nowIso());
  const id = Number(lastInsertRowid);

  json(res, { token: issueToken(id), user: { id, email, name } }, 201);
}

/** POST /auth/login  {email, password} -> 200 {token, user} */
export function login(req, res) {
  const email = stringField(req.body, 'email');
  const password = stringField(req.body, 'password');
  if (email === null || password === null) {
    return unauthorized(res, 'Invalid email or password');
  }

  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  if (user === undefined || !verifyPassword(password, user.password_hash)) {
    return unauthorized(res, 'Invalid email or password');
  }

  json(res, {
    token: issueToken(user.id),
    user: { id: user.id, email: user.email, name: user.name },
  });
}

/** GET /me  (Bearer) -> 200 {id, email, name} */
export function me(req, res) {
  const user = db
    .prepare('SELECT id, email, name FROM users WHERE id = ?')
    .get(req.userId);
  if (user === undefined) return unauthorized(res);
  json(res, { id: user.id, email: user.email, name: user.name });
}

// ---------------------------------------------------------------------------
// Auth middleware
// ---------------------------------------------------------------------------

/**
 * Express middleware: the route after it only runs with a valid
 * `Authorization: Bearer` token. Inside the handler, the logged-in user
 * is available as `req.userId`.
 */
export function requireAuth(req, res, next) {
  const header = req.headers.authorization ?? '';
  if (!header.startsWith('Bearer ')) return unauthorized(res);
  const userId = verifyToken(header.slice('Bearer '.length));
  if (userId === null) return unauthorized(res);
  req.userId = userId;
  next();
}

// ---------------------------------------------------------------------------
// JWT (HS256), implemented by hand so you can see exactly how it works.
// A JWT is:  base64url(header) . base64url(payload) . signature
// where signature = HMAC-SHA256("header.payload", secret).
// ---------------------------------------------------------------------------

/** Creates a token for userId, valid for 7 days. `sub` holds the user id. */
export function issueToken(userId) {
  const header = b64Json({ alg: 'HS256', typ: 'JWT' });
  const now = Math.floor(Date.now() / 1000);
  const payload = b64Json({
    sub: String(userId),
    iat: now,
    exp: now + 7 * 24 * 60 * 60, // 7 days
  });
  return `${header}.${payload}.${sign(`${header}.${payload}`)}`;
}

/** Returns the user id from a valid token, or null when invalid/expired. */
export function verifyToken(token) {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  if (!constantTimeEquals(sign(`${parts[0]}.${parts[1]}`), parts[2])) {
    return null;
  }
  try {
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
    const now = Math.floor(Date.now() / 1000);
    if (typeof payload.exp !== 'number' || now >= payload.exp) return null;
    const sub = Number.parseInt(payload.sub, 10);
    return Number.isNaN(sub) ? null : sub;
  } catch {
    return null;
  }
}

// Node's 'base64url' encoding is already unpadded — exactly the JWT format.
const b64Json = (data) => Buffer.from(JSON.stringify(data)).toString('base64url');

const sign = (data) =>
  createHmac('sha256', jwtSecret).update(data).digest('base64url');

// ---------------------------------------------------------------------------
// Passwords: scrypt with a random salt (no plaintext, ever). scrypt ships
// in node:crypto, so no bcrypt dependency is needed in Node.
// Stored as "scrypt:salt:hash" (salt and hash base64-encoded).
// ---------------------------------------------------------------------------

export function hashPassword(password) {
  const salt = randomBytes(16);
  const hash = scryptSync(password, salt, 32);
  return `scrypt:${salt.toString('base64')}:${hash.toString('base64')}`;
}

export function verifyPassword(password, stored) {
  const parts = stored.split(':');
  if (parts.length !== 3 || parts[0] !== 'scrypt') return false;
  const expected = Buffer.from(parts[2], 'base64');
  if (expected.length !== 32) return false;
  const actual = scryptSync(password, Buffer.from(parts[1], 'base64'), 32);
  return timingSafeEqual(actual, expected);
}

/** Compares two strings without leaking where they differ (timing attacks). */
function constantTimeEquals(a, b) {
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  return bufA.length === bufB.length && timingSafeEqual(bufA, bufB);
}
