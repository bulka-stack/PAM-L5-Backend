// Общие помощники для списков StudyCards: ?page=&limit= (как у notes) и строгий разбор id.

/** {page, limit, offset} из query; limit 1..100, по умолчанию 20 — ровно как в notes.js. */
export function paging(query) {
  const pageRaw = Number.parseInt(query.page, 10);
  const page = Math.max(Number.isNaN(pageRaw) ? 1 : pageRaw, 1);
  const limitRaw = Number.parseInt(query.limit, 10);
  const limit = Math.min(Math.max(Number.isNaN(limitRaw) ? 20 : limitRaw, 1), 100);
  return { page, limit, offset: (page - 1) * limit };
}

/** Строгий разбор id: только цифры, иначе null (как find() в notes.js). */
export function parseId(value) {
  const s = String(value ?? '');
  return /^\d+$/.test(s) ? Number.parseInt(s, 10) : null;
}
