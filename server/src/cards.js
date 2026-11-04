// Cards: карточки колод. Принадлежность — через колоду (decks.user_id).
// PUT /cards/{id} — это и редактирование сторон, и обновление расписания после оценки (SRS).

import { db, nowIso } from './db.js';
import { findDeck } from './decks.js';
import { json, notFound, stringField, validationError } from './errors.js';
import { paging, parseId } from './paging.js';

const toJson = (row) => ({
  id: row.id,
  deckId: row.deck_id,
  front: row.front,
  back: row.back,
  easeFactor: row.ease_factor,
  intervalDays: row.interval_days,
  nextReviewAt: row.next_review_at,
  createdAt: row.created_at,
});

const OWNED = 'FROM cards c JOIN decks d ON d.id = c.deck_id WHERE d.user_id = ?';

function findCard(userId, idParam) {
  const id = parseId(idParam);
  if (id === null) return undefined;
  return db.prepare(`SELECT c.* ${OWNED} AND c.id = ?`).get(userId, id);
}

/** Поля карточки из тела; current — значения по умолчанию (для PUT — старые). */
function readBody(body, current) {
  const front = stringField(body, 'front');
  if (front === null) return { error: 'front is required' };
  const back = stringField(body, 'back');
  if (back === null) return { error: 'back is required' };

  const ease = body?.easeFactor ?? current.easeFactor;
  if (typeof ease !== 'number' || !Number.isFinite(ease) || ease < 1.3 || ease > 5) {
    return { error: 'easeFactor must be a number between 1.3 and 5' };
  }
  const interval = body?.intervalDays ?? current.intervalDays;
  if (!Number.isInteger(interval) || interval < 0) {
    return { error: 'intervalDays must be a non-negative integer' };
  }
  const next = body?.nextReviewAt ?? current.nextReviewAt;
  if (typeof next !== 'string' || Number.isNaN(Date.parse(next))) {
    return { error: 'nextReviewAt must be an ISO-8601 date' };
  }
  return { front, back, ease, interval, next: new Date(next).toISOString() };
}

/** GET /cards?deckId=&page=&limit=&search= -> {items, page, limit, total} */
export function listCards(req, res) {
  const { page, limit, offset } = paging(req.query);
  const search = typeof req.query.search === 'string' ? req.query.search : '';
  let where = `${OWNED} AND (c.front LIKE ? OR c.back LIKE ?)`;
  const args = [req.userId, `%${search}%`, `%${search}%`];
  if (req.query.deckId !== undefined) {
    const deckId = parseId(req.query.deckId);
    if (deckId === null) return validationError(res, 'deckId must be an integer');
    where += ' AND c.deck_id = ?';
    args.push(deckId);
  }
  const total = db.prepare(`SELECT COUNT(*) AS n ${where}`).get(...args).n;
  const rows = db
    .prepare(`SELECT c.* ${where} ORDER BY c.id ASC LIMIT ? OFFSET ?`)
    .all(...args, limit, offset);
  json(res, { items: rows.map(toJson), page, limit, total });
}

/** POST /cards {deckId, front, back, [easeFactor, intervalDays, nextReviewAt]} -> 201 */
export function createCard(req, res) {
  const deck = findDeck(req.userId, String(req.body?.deckId ?? ''));
  if (deck === undefined) return validationError(res, 'deckId must reference your deck');
  const data = readBody(req.body, {
    easeFactor: 2.5, // начальный ease (упрощённый SM-2)
    intervalDays: 0,
    nextReviewAt: nowIso(), // новая карточка — к повторению сразу
  });
  if (data.error) return validationError(res, data.error);
  const { lastInsertRowid } = db
    .prepare(
      'INSERT INTO cards (deck_id, front, back, ease_factor, interval_days, next_review_at, created_at) ' +
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
    )
    .run(deck.id, data.front, data.back, data.ease, data.interval, data.next, nowIso());
  json(res, toJson(findCard(req.userId, String(lastInsertRowid))), 201);
}

/** GET /cards/{id} -> 200 | 404 */
export function getCard(req, res) {
  const row = findCard(req.userId, req.params.id);
  if (row === undefined) return notFound(res, 'Card not found');
  json(res, toJson(row));
}

/** PUT /cards/{id} -> 200 | 404 — стороны и/или расписание (easeFactor, intervalDays, nextReviewAt). */
export function updateCard(req, res) {
  const row = findCard(req.userId, req.params.id);
  if (row === undefined) return notFound(res, 'Card not found');
  const data = readBody(req.body, toJson(row));
  if (data.error) return validationError(res, data.error);
  db.prepare(
    'UPDATE cards SET front = ?, back = ?, ease_factor = ?, interval_days = ?, next_review_at = ? WHERE id = ?',
  ).run(data.front, data.back, data.ease, data.interval, data.next, row.id);
  json(res, toJson(findCard(req.userId, String(row.id))));
}

/** DELETE /cards/{id} -> 204 | 404 */
export function deleteCard(req, res) {
  const row = findCard(req.userId, req.params.id);
  if (row === undefined) return notFound(res, 'Card not found');
  db.prepare('DELETE FROM cards WHERE id = ?').run(row.id);
  res.status(204).end();
}
