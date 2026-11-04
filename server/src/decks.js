// Decks: колоды пользователя. Копия шаблона notes.js с другими существительными:
// список с пагинацией/поиском, создание с валидацией (400), get/put/delete с 404.
// cardCount вычисляется backend-ом (COUNT по таблице cards) — как требует ТЗ темы.

import { db, nowIso } from './db.js';
import { json, notFound, stringField, validationError } from './errors.js';
import { paging, parseId } from './paging.js';

const SELECT = `
  SELECT d.*, (SELECT COUNT(*) FROM cards c WHERE c.deck_id = d.id) AS card_count
  FROM decks d`;

const toJson = (row) => ({
  id: row.id,
  userId: row.user_id,
  name: row.name,
  subject: row.subject,
  cardCount: row.card_count,
  createdAt: row.created_at,
});

/** Колода только среди колод текущего пользователя: чужая неотличима от отсутствующей (404). */
export function findDeck(userId, idParam) {
  const id = parseId(idParam);
  if (id === null) return undefined;
  return db.prepare(`${SELECT} WHERE d.id = ? AND d.user_id = ?`).get(id, userId);
}

function readBody(body) {
  const name = stringField(body, 'name');
  if (name === null) return { error: 'name is required' };
  if (name.length > 60) return { error: 'name must be at most 60 characters' };
  const subject = stringField(body, 'subject');
  if (subject === null) return { error: 'subject is required' };
  return { name, subject };
}

/** GET /decks?page=1&limit=20&search=  -> {items, page, limit, total} */
export function listDecks(req, res) {
  const { page, limit, offset } = paging(req.query);
  const search = typeof req.query.search === 'string' ? req.query.search : '';
  const where = 'd.user_id = ? AND (d.name LIKE ? OR d.subject LIKE ?)';
  const args = [req.userId, `%${search}%`, `%${search}%`];

  const total = db.prepare(`SELECT COUNT(*) AS n FROM decks d WHERE ${where}`).get(...args).n;
  const rows = db
    .prepare(`${SELECT} WHERE ${where} ORDER BY d.id ASC LIMIT ? OFFSET ?`)
    .all(...args, limit, offset);
  json(res, { items: rows.map(toJson), page, limit, total });
}

/** POST /decks {name, subject} -> 201 deck */
export function createDeck(req, res) {
  const data = readBody(req.body);
  if (data.error) return validationError(res, data.error);
  const { lastInsertRowid } = db
    .prepare('INSERT INTO decks (user_id, name, subject, created_at) VALUES (?, ?, ?, ?)')
    .run(req.userId, data.name, data.subject, nowIso());
  json(res, toJson(findDeck(req.userId, String(lastInsertRowid))), 201);
}

/** GET /decks/{id} -> 200 | 404 */
export function getDeck(req, res) {
  const row = findDeck(req.userId, req.params.id);
  if (row === undefined) return notFound(res, 'Deck not found');
  json(res, toJson(row));
}

/** PUT /decks/{id} {name, subject} -> 200 | 404 */
export function updateDeck(req, res) {
  const row = findDeck(req.userId, req.params.id);
  if (row === undefined) return notFound(res, 'Deck not found');
  const data = readBody(req.body);
  if (data.error) return validationError(res, data.error);
  db.prepare('UPDATE decks SET name = ?, subject = ? WHERE id = ?').run(data.name, data.subject, row.id);
  json(res, toJson(findDeck(req.userId, String(row.id))));
}

/** DELETE /decks/{id} -> 204 | 404. Карточки и сессии колоды удаляются вместе с ней. */
export function deleteDeck(req, res) {
  const row = findDeck(req.userId, req.params.id);
  if (row === undefined) return notFound(res, 'Deck not found');
  db.prepare('DELETE FROM cards WHERE deck_id = ?').run(row.id);
  db.prepare('DELETE FROM review_sessions WHERE deck_id = ?').run(row.id);
  db.prepare('DELETE FROM decks WHERE id = ?').run(row.id);
  res.status(204).end();
}
