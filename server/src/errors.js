// Standard responses and small JSON helpers used by every route.
//
// Every error in the API has the same shape:
//   {"error": {"code": "SOME_CODE", "message": "human readable text"}}

/** Sends `data` as a JSON response. */
export function json(res, data, status = 200) {
  res.status(status).json(data);
}

/** The standard error body: {"error": {"code": ..., "message": ...}}. */
export function apiError(res, status, code, message) {
  res.status(status).json({ error: { code, message } });
}

export const validationError = (res, message) =>
  apiError(res, 400, 'VALIDATION_ERROR', message);

export const unauthorized = (res, message = 'Missing or invalid token') =>
  apiError(res, 401, 'UNAUTHORIZED', message);

export const notFound = (res, message = 'Resource not found') =>
  apiError(res, 404, 'NOT_FOUND', message);

export const emailTaken = (res) =>
  apiError(res, 409, 'EMAIL_TAKEN', 'An account with this email already exists');

/** Returns body[key] as a trimmed non-empty string, or null when missing. */
export function stringField(body, key) {
  if (body === null || typeof body !== 'object') return null;
  const value = body[key];
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed === '' ? null : trimmed;
}
