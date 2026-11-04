// Контрактный тест backend-а (замена набора conformance/, которого нет в выданном kit-е).
// Бьёт по запущенному серверу через HTTP — так же, как это делает Flutter-приложение.
// Запуск: npm start (в одном терминале), затем npm run check [-- http://localhost:8080]

const base = process.argv[2] ?? process.env.BASE_URL ?? 'http://localhost:8080';
let passed = 0;
let failed = 0;

function check(name, cond, extra = '') {
  if (cond) {
    passed++;
    console.log(`  ✓ ${name}`);
  } else {
    failed++;
    console.log(`  ✗ ${name} ${extra}`);
  }
}

async function call(method, path, { token, body } = {}) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  const res = await fetch(base + path, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = null;
  }
  return { status: res.status, json, text };
}

const isError = (r, status, code) => r.status === status && r.json?.error?.code === code;

const email = `check_${Date.now()}@test.md`;
const other = `other_${Date.now()}@test.md`;

console.log(`Проверка контракта: ${base}\n`);

console.log('Базовый контракт шаблона');
check('GET /health -> 200 {status: ok}', (await call('GET', '/health')).json?.status === 'ok');
check('GET /notes без token -> 401 UNAUTHORIZED', isError(await call('GET', '/notes'), 401, 'UNAUTHORIZED'));
const reg = await call('POST', '/auth/register', { body: { email, password: 'parola123', name: 'Check' } });
check('POST /auth/register -> 201 {token, user}', reg.status === 201 && typeof reg.json?.token === 'string');
const token = reg.json?.token;
check('POST /auth/register тот же email -> 409 EMAIL_TAKEN',
  isError(await call('POST', '/auth/register', { body: { email, password: 'x', name: 'X' } }), 409, 'EMAIL_TAKEN'));
check('POST /auth/register без name -> 400 VALIDATION_ERROR',
  isError(await call('POST', '/auth/register', { body: { email: 'a@b.md', password: 'x' } }), 400, 'VALIDATION_ERROR'));
check('POST /auth/login верно -> 200 token',
  (await call('POST', '/auth/login', { body: { email, password: 'parola123' } })).json?.token !== undefined);
check('POST /auth/login неверный пароль -> 401',
  isError(await call('POST', '/auth/login', { body: { email, password: 'wrong' } }), 401, 'UNAUTHORIZED'));
check('GET /me -> 200 {id, email, name}', (await call('GET', '/me', { token })).json?.email === email);
check('Bearer с чужой подписью -> 401',
  isError(await call('GET', '/me', { token: token.slice(0, -3) + 'abc' }), 401, 'UNAUTHORIZED'));
const note = await call('POST', '/notes', { token, body: { title: 'Покупки', content: 'молоко' } });
check('POST /notes -> 201, id от сервера', note.status === 201 && Number.isInteger(note.json?.id));
const notes = await call('GET', '/notes?search=' + encodeURIComponent('Покуп'), { token });
check('GET /notes?search= -> пагинированный конверт',
  notes.status === 200 && notes.json?.items?.length === 1 && notes.json.page === 1 && notes.json.total === 1);
check('GET /notes/999999 -> 404 NOT_FOUND', isError(await call('GET', '/notes/999999', { token }), 404, 'NOT_FOUND'));
const broken = await fetch(base + '/notes', {
  method: 'POST',
  headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  body: '{oops',
});
check('Битый JSON -> 400 VALIDATION_ERROR',
  isError({ status: broken.status, json: await broken.json() }, 400, 'VALIDATION_ERROR'));
check('DELETE /notes/{id} -> 204', (await call('DELETE', `/notes/${note.json.id}`, { token })).status === 204);
check('Неизвестный маршрут -> 404 в стандартной форме', isError(await call('GET', '/nope', { token }), 404, 'NOT_FOUND'));

console.log('\nСущности StudyCards (T13)');
check('GET /decks без token -> 401', isError(await call('GET', '/decks'), 401, 'UNAUTHORIZED'));
check('POST /decks без name -> 400', isError(await call('POST', '/decks', { token, body: { subject: 'Языки' } }), 400, 'VALIDATION_ERROR'));
const deck = await call('POST', '/decks', { token, body: { name: 'Английский: IT', subject: 'Языки' } });
check('POST /decks -> 201, cardCount = 0', deck.status === 201 && deck.json?.cardCount === 0);
const deckId = deck.json?.id;
const card = await call('POST', '/cards', { token, body: { deckId, front: 'latency', back: 'задержка' } });
check('POST /cards -> 201, ease 2.5, interval 0',
  card.status === 201 && card.json?.easeFactor === 2.5 && card.json?.intervalDays === 0);
check('POST /cards пустая обратная сторона -> 400',
  isError(await call('POST', '/cards', { token, body: { deckId, front: 'x', back: '  ' } }), 400, 'VALIDATION_ERROR'));
check('GET /decks/{id}: cardCount считает backend -> 1', (await call('GET', `/decks/${deckId}`, { token })).json?.cardCount === 1);
const next = new Date(Date.now() + 3 * 86400000).toISOString();
const upd = await call('PUT', `/cards/${card.json.id}`, {
  token, body: { front: 'latency', back: 'задержка', easeFactor: 2.3, intervalDays: 3, nextReviewAt: next },
});
check('PUT /cards/{id} обновляет расписание', upd.status === 200 && upd.json?.intervalDays === 3 && upd.json?.easeFactor === 2.3);
check('PUT /cards/{id} ease < 1.3 -> 400', isError(await call('PUT', `/cards/${card.json.id}`, {
  token, body: { front: 'a', back: 'b', easeFactor: 1 } }), 400, 'VALIDATION_ERROR'));
check('GET /cards?deckId= -> конверт', (await call('GET', `/cards?deckId=${deckId}`, { token })).json?.total === 1);
const s = await call('POST', '/review-sessions', { token, body: { deckId, reviewedCount: 10, correctCount: 8 } });
check('POST /review-sessions -> 201', s.status === 201 && s.json?.correctCount === 8);
check('POST /review-sessions correct > reviewed -> 400', isError(await call('POST', '/review-sessions', {
  token, body: { deckId, reviewedCount: 2, correctCount: 3 } }), 400, 'VALIDATION_ERROR'));
check('GET /review-sessions -> конверт', (await call('GET', '/review-sessions', { token })).json?.total === 1);
for (let i = 0; i < 22; i++) {
  await call('POST', '/decks', { token, body: { name: `Колода ${i}`, subject: 'Математика' } });
}
const p1 = await call('GET', '/decks?page=1&limit=20', { token });
const p2 = await call('GET', '/decks?page=2&limit=20', { token });
check('Пагинация /decks: 20 + 3 из 23', p1.json?.items?.length === 20 && p2.json?.items?.length === 3 && p1.json.total === 23);
check('Поиск /decks?search= на сервере', (await call('GET', '/decks?search=' + encodeURIComponent('Английский'), { token })).json?.total === 1);

const reg2 = await call('POST', '/auth/register', { body: { email: other, password: 'parola123', name: 'Other' } });
const token2 = reg2.json?.token;
check('Чужая колода -> 404 (не 403)', isError(await call('GET', `/decks/${deckId}`, { token: token2 }), 404, 'NOT_FOUND'));
check('Чужая карточка -> 404', isError(await call('GET', `/cards/${card.json.id}`, { token: token2 }), 404, 'NOT_FOUND'));
check('DELETE /review-sessions/{id} -> 204', (await call('DELETE', `/review-sessions/${s.json.id}`, { token })).status === 204);
check('DELETE /decks/{id} -> 204, карточки удалены каскадом',
  (await call('DELETE', `/decks/${deckId}`, { token })).status === 204 &&
  (await call('GET', `/cards/${card.json.id}`, { token })).status === 404);

console.log(`\n${failed === 0 ? 'PASS' : 'FAIL'} — ${passed}/${passed + failed} checks passed`);
process.exit(failed === 0 ? 0 : 1);
