// PAM backend template - Node.js/Express port.
//
// Start:  npm install && npm start
// Env:    PORT (default 8080), JWT_SECRET (default dev-secret-change-me)

import express from 'express';

import { login, me, register, requireAuth } from './src/auth.js';
import { initDb } from './src/db.js';
import { apiError, json, notFound, validationError } from './src/errors.js';
import { downloadFile, initFileStorage, uploadFile } from './src/files.js';
import { createDeck, deleteDeck, getDeck, listDecks, updateDeck } from './src/decks.js';
import {
  createNote,
  deleteNote,
  getNote,
  listNotes,
  updateNote,
} from './src/notes.js';

const port = Number.parseInt(process.env.PORT ?? '', 10) || 8080;

initDb('app.db'); // creates app.db + schema on first start
initFileStorage('uploads'); // creates uploads/ on first start

const app = express();
app.disable('x-powered-by');

// --------------------------------------------------------------- middleware

// Permissive CORS so a Flutter *web* build can call the API during the labs.
app.use((req, res, next) => {
  res.set({
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
  });
  if (req.method === 'OPTIONS') return res.status(200).end();
  next();
});

// Tiny request log, e.g. "POST /notes -> 201 (3 ms)".
app.use((req, res, next) => {
  const started = Date.now();
  res.on('finish', () => {
    console.log(
      `${req.method} ${req.originalUrl} -> ${res.statusCode} ` +
        `(${Date.now() - started} ms)`,
    );
  });
  next();
});

// Parses application/json bodies into req.body. Multipart bodies are
// handled separately, by multer in src/files.js.
app.use(express.json());

// ------------------------------------------------------------------- routes

app.get('/health', (req, res) => json(res, { status: 'ok' }));
app.post('/auth/register', register);
app.post('/auth/login', login);
app.get('/me', requireAuth, me);
// Notes: the example entity. Register your own routes the same way.
app.get('/notes', requireAuth, listNotes);
app.post('/notes', requireAuth, createNote);
app.get('/notes/:id', requireAuth, getNote);
app.put('/notes/:id', requireAuth, updateNote);
app.delete('/notes/:id', requireAuth, deleteNote);
// StudyCards (тема T13): колоды, карточки, сессии повторения — под тем же requireAuth.
app.get('/decks', requireAuth, listDecks);
app.post('/decks', requireAuth, createDeck);
app.get('/decks/:id', requireAuth, getDeck);
app.put('/decks/:id', requireAuth, updateDeck);
app.delete('/decks/:id', requireAuth, deleteDeck);
app.post('/files', requireAuth, uploadFile);
app.get('/files/:id', downloadFile);

// -------------------------------- fallbacks: the standard error shape only

// Unknown route -> 404 {"error":{...}} instead of Express's HTML page.
app.use((req, res) => notFound(res, 'Route not found'));

// Any error escaping a route. The interesting case is express.json()
// rejecting a body (malformed JSON, or over its 100 kB default limit) —
// both are client mistakes, so they answer 400 VALIDATION_ERROR.
app.use((err, req, res, next) => {
  if (res.headersSent) return next(err);
  if (err.type === 'entity.parse.failed') {
    return validationError(res, 'Body must be valid JSON');
  }
  if (err.type === 'entity.too.large') {
    return validationError(res, 'JSON body too large');
  }
  console.error(err);
  apiError(res, 500, 'INTERNAL', 'Internal server error');
});

app.listen(port, () => {
  console.log(`Backend listening on http://localhost:${port}`);
});
