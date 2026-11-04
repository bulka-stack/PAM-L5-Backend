// File upload/download. Bytes live in uploads/, metadata in the database.

import { randomUUID } from 'node:crypto';
import { createReadStream, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

import multer from 'multer';

import { db, nowIso } from './db.js';
import { json, notFound, validationError } from './errors.js';

/**
 * Upload size cap: 5 MB — plenty for lab photos. Documented in
 * ../openapi.yaml at POST /files. Over the cap -> 400 VALIDATION_ERROR
 * (the contract deliberately has no 413).
 */
export const maxUploadBytes = 5 * 1024 * 1024;

const tooLarge = (res) =>
  validationError(
    res,
    `File too large: the upload limit is 5 MB (${maxUploadBytes} bytes)`,
  );

let uploadsDir;

/** Creates the uploads/ folder on first start. */
export function initFileStorage(path) {
  uploadsDir = path;
  mkdirSync(uploadsDir, { recursive: true });
}

// multer parses the multipart body into memory and enforces the size cap by
// counting the actual bytes — this covers chunked uploads and clients whose
// Content-Length lies.
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: maxUploadBytes, files: 1 },
});

/** POST /files  (multipart, field "file") -> 201 {id, url, name, size, mimeType} */
export function uploadFile(req, res) {
  // Cheap early rejection when the client declares the size upfront.
  // Not sufficient on its own: Content-Length can be absent (chunked
  // encoding) or lie, so multer counts the bytes again while reading.
  const declared = Number.parseInt(req.headers['content-length'] ?? '', 10);
  if (!Number.isNaN(declared) && declared > maxUploadBytes) return tooLarge(res);

  // multer is invoked by hand (instead of as route middleware) so that every
  // way a multipart body can go wrong — corrupt boundary, truncated part,
  // over the size cap — answers 400 immediately, instead of crashing the
  // handler or leaving the client's connection hanging.
  upload.single('file')(req, res, (err) => {
    if (err) {
      if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
        return tooLarge(res);
      }
      if (err instanceof multer.MulterError && err.code === 'LIMIT_UNEXPECTED_FILE') {
        return validationError(res, "Expected exactly one file, in the multipart field 'file'");
      }
      return validationError(res, 'Malformed multipart/form-data body');
    }
    if (req.file === undefined) {
      return validationError(res, "Missing multipart field 'file'");
    }

    const name = req.file.originalname || 'file';
    const mimeType = req.file.mimetype || 'application/octet-stream';

    // Store under a unique name: no collisions, no path tricks.
    const safeName = name.replace(/[^A-Za-z0-9._-]/g, '_');
    const storedPath = join(uploadsDir, `${randomUUID()}_${safeName}`);
    writeFileSync(storedPath, req.file.buffer);

    const { lastInsertRowid } = db
      .prepare(
        'INSERT INTO files (user_id, name, mime_type, size, path, created_at) ' +
          'VALUES (?, ?, ?, ?, ?, ?)',
      )
      .run(req.userId, name, mimeType, req.file.size, storedPath, nowIso());
    const id = Number(lastInsertRowid);

    json(res, { id, url: `/files/${id}`, name, size: req.file.size, mimeType }, 201);
  });
}

/**
 * GET /files/{id} -> the stored bytes with their original Content-Type | 404
 * Public on purpose: lets a Flutter app show images by plain URL.
 */
export function downloadFile(req, res) {
  // Strict digits-only parse: parseInt alone would accept "7abc" as 7,
  // while every other port answers 404 for such an id.
  if (!/^\d+$/.test(req.params.id ?? '')) return notFound(res, 'File not found');
  const id = Number.parseInt(req.params.id, 10);

  const row = db.prepare('SELECT * FROM files WHERE id = ?').get(id);
  if (row === undefined || !existsSync(row.path)) {
    return notFound(res, 'File not found');
  }

  // setHeader (not Express's res.set/res.type) keeps the Content-Type
  // byte-for-byte as uploaded — Express would append "; charset=utf-8"
  // to text types.
  res.setHeader('Content-Type', row.mime_type);
  res.setHeader('Content-Length', String(row.size));
  // The stored Content-Type is client-supplied; nosniff stops browsers
  // from second-guessing it into something executable.
  res.setHeader('X-Content-Type-Options', 'nosniff');
  // Anyone can upload text/html or image/svg+xml, so a direct visit to this
  // URL would run their scripts on our origin (stored XSS). attachment =
  // browsers download instead of rendering; the CSP sandbox neutralizes
  // anything that still renders. <img> tags and Flutter's Image.network
  // ignore both, so images keep working.
  res.setHeader('Content-Disposition', 'attachment');
  res.setHeader('Content-Security-Policy', "default-src 'none'; sandbox");
  createReadStream(row.path).pipe(res);
}
