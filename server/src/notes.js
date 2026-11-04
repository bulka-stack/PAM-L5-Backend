// Notes: the example CRUD entity, scoped per user.
//
// THIS FILE IS THE TEMPLATE FOR YOUR OWN ENTITIES.
// To add e.g. "recipes": copy this file to recipes.js, rename the table
// and the fields, add a CREATE TABLE in db.js, register routes in
// server.js. That's the whole recipe.

import { db, nowIso } from './db.js';
import { json, notFound, stringField, validationError } from './errors.js';

const toJson = (row) => ({
  id: row.id,
  title: row.title,
  content: row.content,
  createdAt: row.created_at,
});

/**
 * Finds a note by id, but only among the current user's notes.
 * Someone else's note is indistinguishable from a missing one (404).
 */
function find(userId, idParam) {
  // Strict digits-only parse: parseInt alone would accept "7abc" as 7,
  // while every other port answers 404 for such an id.
  if (!/^\d+$/.test(idParam ?? '')) return undefined;
  const id = Number.parseInt(idParam, 10);
  return db
    .prepare('SELECT * FROM notes WHERE id = ? AND user_id = ?')
    .get(id, userId);
}

/** GET /notes?page=1&limit=20&search=  -> {items, page, limit, total} */
export function listNotes(req, res) {
  const pageRaw = Number.parseInt(req.query.page, 10);
  const page = Math.max(Number.isNaN(pageRaw) ? 1 : pageRaw, 1);
  const limitRaw = Number.parseInt(req.query.limit, 10);
  const limit = Math.min(Math.max(Number.isNaN(limitRaw) ? 20 : limitRaw, 1), 100);
  const search = typeof req.query.search === 'string' ? req.query.search : '';

  const where = 'user_id = ? AND (title LIKE ? OR content LIKE ?)';
  // %/_ in the search term act as LIKE wildcards (parameterized, so safe —
  // purely a semantic quirk).
  const args = [req.userId, `%${search}%`, `%${search}%`];

  const total = db
    .prepare(`SELECT COUNT(*) AS n FROM notes WHERE ${where}`)
    .get(...args).n;
  const rows = db
    .prepare(`SELECT * FROM notes WHERE ${where} ORDER BY id DESC LIMIT ? OFFSET ?`)
    .all(...args, limit, (page - 1) * limit);

  json(res, { items: rows.map(toJson), page, limit, total });
}

/** POST /notes  {title, content} -> 201 note */
export function createNote(req, res) {
  const title = stringField(req.body, 'title');
  if (title === null) return validationError(res, 'title is required');
  const content = typeof req.body?.content === 'string' ? req.body.content : '';

  const { lastInsertRowid } = db
    .prepare(
      'INSERT INTO notes (user_id, title, content, created_at) ' +
        'VALUES (?, ?, ?, ?)',
    )
    .run(req.userId, title, content, nowIso());
  json(res, toJson(find(req.userId, String(lastInsertRowid))), 201);
}

/** GET /notes/{id} -> 200 note | 404 */
export function getNote(req, res) {
  const row = find(req.userId, req.params.id);
  if (row === undefined) return notFound(res, 'Note not found');
  json(res, toJson(row));
}

/** PUT /notes/{id}  {title, content} -> 200 updated note | 404 */
export function updateNote(req, res) {
  const row = find(req.userId, req.params.id);
  if (row === undefined) return notFound(res, 'Note not found');

  const title = stringField(req.body, 'title');
  if (title === null) return validationError(res, 'title is required');
  const content = typeof req.body?.content === 'string' ? req.body.content : '';

  db.prepare('UPDATE notes SET title = ?, content = ? WHERE id = ?').run(
    title,
    content,
    row.id,
  );
  json(res, toJson(find(req.userId, String(row.id))));
}

/** DELETE /notes/{id} -> 204 | 404 */
export function deleteNote(req, res) {
  const row = find(req.userId, req.params.id);
  if (row === undefined) return notFound(res, 'Note not found');
  db.prepare('DELETE FROM notes WHERE id = ?').run(row.id);
  res.status(204).end();
}
