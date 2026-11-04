// Демо-данные для защиты: пользователь + 24 колоды (больше одной страницы по 20) + сессии.
// Данные идут через тот же HTTP API, что и у приложения. Запуск при запущенном сервере:
//   npm run seed            → пользователь andrii.kostin@isa.utm.md / parola123
import { readFileSync } from 'node:fs';

const base = process.argv[2] ?? process.env.BASE_URL ?? 'http://localhost:8080';
const user = { email: 'andrii.kostin@isa.utm.md', password: 'parola123', name: 'Андрей Костин' };
const data = JSON.parse(readFileSync(new URL('./seed_data.json', import.meta.url), 'utf8'));

async function call(method, path, token, body) {
  const res = await fetch(base + path, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const json = res.status === 204 ? null : await res.json();
  if (res.status >= 400) throw new Error(`${method} ${path} -> ${res.status} ${JSON.stringify(json)}`);
  return json;
}

let auth;
try {
  auth = await call('POST', '/auth/register', null, user);
} catch {
  auth = await call('POST', '/auth/login', null, { email: user.email, password: user.password });
}
const token = auth.token;
const existing = await call('GET', '/decks?limit=1', token);
if (existing.total > 0) {
  console.log(`У ${user.email} уже есть ${existing.total} колод — seed пропущен.`);
  process.exit(0);
}

const midnight = new Date();
midnight.setHours(0, 0, 0, 0);
const day = (n) => new Date(midnight.getTime() + n * 86400000).toISOString();

const ids = [];
for (const d of data.decks) {
  const deck = await call('POST', '/decks', token, { name: d.name, subject: d.subject });
  ids.push(deck.id);
  for (const c of d.cards) {
    await call('POST', '/cards', token, {
      deckId: deck.id,
      front: c.front,
      back: c.back,
      easeFactor: c.ease,
      intervalDays: c.interval,
      nextReviewAt: day(c.days),
    });
  }
}
for (const s of data.sessions) {
  const date = new Date(midnight.getTime() - s.daysAgo * 86400000);
  date.setHours(s.h, s.m);
  await call('POST', '/review-sessions', token, {
    deckId: ids[s.deck],
    date: date.toISOString(),
    reviewedCount: s.reviewed,
    correctCount: s.correct,
  });
}
console.log(`Готово: ${ids.length} колод, ${data.sessions.length} сессий для ${user.email} / ${user.password}`);
