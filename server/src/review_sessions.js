// ReviewSessions: история сессий повторения (для статистики).

import { db } from './db.js';
import { findDeck } from './decks.js';
import { json, notFound, validationError } from './errors.js';
import { paging, parseId } from './paging.js';

const toJson = (row) => ({
  id: row.id,
  deckId: row.deck_id,
  date: row.date,
  reviewedCount: row.reviewed_count,
  correctCount: row.correct_count,
});

/** GET /review-sessions?page=&limit=&deckId= -> {items, page, limit, total}, новые сверху */
export function listSessions(req, res) {
  const { page, limit, offset } = paging(req.query);
  let where = 'WHERE user_id = ?';
  const args = [req.userId];
  if (req.query.deckId !== undefined) {
    const deckId = parseId(req.query.deckId);
    if (deckId === null) return validationError(res, 'deckId must be an integer');
    where += ' AND deck_id = ?';
    args.push(deckId);
  }
  const total = db.prepare(`SELECT COUNT(*) AS n FROM review_sessions ${where}`).get(...args).n;
  const rows = db
    .prepare(`SELECT * FROM review_sessions ${where} ORDER BY date DESC, id DESC LIMIT ? OFFSET ?`)
    .all(...args, limit, offset);
  json(res, { items: rows.map(toJson), page, limit, total });
}

/** POST /review-sessions {deckId, reviewedCount, correctCount, [date]} -> 201 */
export function createSession(req, res) {
  const deck = findDeck(req.userId, String(req.body?.deckId ?? ''));
  if (deck === undefined) return validationError(res, 'deckId must reference your deck');
  const reviewed = req.body?.reviewedCount;
  const correct = req.body?.correctCount;
  if (!Number.isInteger(reviewed) || reviewed < 1) {
    return validationError(res, 'reviewedCount must be a positive integer');
  }
  if (!Number.isInteger(correct) || correct < 0 || correct > reviewed) {
    return validationError(res, 'correctCount must be between 0 and reviewedCount');
  }
  const date = req.body?.date ?? new Date().toISOString();
  if (typeof date !== 'string' || Number.isNaN(Date.parse(date))) {
    return validationError(res, 'date must be an ISO-8601 date');
  }
  const { lastInsertRowid } = db
    .prepare(
      'INSERT INTO review_sessions (user_id, deck_id, date, reviewed_count, correct_count) VALUES (?, ?, ?, ?, ?)',
    )
    .run(req.userId, deck.id, new Date(date).toISOString(), reviewed, correct);
  const row = db.prepare('SELECT * FROM review_sessions WHERE id = ?').get(lastInsertRowid);
  json(res, toJson(row), 201);
}

/** DELETE /review-sessions/{id} -> 204 | 404 */
export function deleteSession(req, res) {
  const id = parseId(req.params.id);
  const row =
    id === null
      ? undefined
      : db.prepare('SELECT * FROM review_sessions WHERE id = ? AND user_id = ?').get(id, req.userId);
  if (row === undefined) return notFound(res, 'Review session not found');
  db.prepare('DELETE FROM review_sessions WHERE id = ?').run(row.id);
  res.status(204).end();
}
