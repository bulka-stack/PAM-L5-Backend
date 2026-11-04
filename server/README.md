# Node.js + Express — portul Node al șablonului

Portul Node.js al backend-șablonului PAM. Implementează exact
[`../openapi.yaml`](../openapi.yaml); contractul și regulile sunt în
README-ul șablonului (`../README_RO.md` / `_RU` / `_EN`).

## Pornire

```bash
npm install   # o singură dată
npm start
```

Atât. `app.db` (SQLite) și `uploads/` se creează automat la prima pornire.

- Env: `PORT` (implicit 8080), `JWT_SECRET` (implicit `dev-secret-change-me`).
- Necesită Node.js ≥ 22.13 (folosim `node:sqlite` din biblioteca standard —
  zero dependențe native de compilat; `npm start` suprimă doar avertismentul
  lui „experimental”, API-ul e stabil în practică).
- Upload-urile sunt limitate la 5 MB per fișier (`POST /files` răspunde 400
  `VALIDATION_ERROR` peste limită). Setările implicite — CORS deschis,
  secretul JWT de dev, limita de 5 MB — sunt pentru laborator, nu pentru
  producție.
- Descărcările (`GET /files/{id}`) pleacă cu `Content-Disposition: attachment`
  și `Content-Security-Policy: default-src 'none'; sandbox`: oricine poate
  încărca `text/html` sau `image/svg+xml`, iar fără aceste antete un link
  deschis direct în browser ar rula scriptul atacatorului pe originea API-ului
  (stored XSS). `Image.network`/`<img>` ignoră ambele antete, deci afișarea
  imaginilor în laborator nu se schimbă — dar șablonul rămâne o configurație
  de laborator, nu de producție.

## Verificarea contra contractului

```bash
# cu serverul pornit:
cd ../conformance
dart pub get
dart run bin/conformance.dart --base-url http://localhost:8080
```

## Structura

```
server.js       — pornirea: env, rute, middleware (CORS, logging, JSON)
src/db.js       — schema SQLite (node:sqlite), aplicată automat la pornire
src/auth.js     — register/login/me, parole cu scrypt, JWT (HS256, manual)
src/notes.js    — entitatea-exemplu: CRUD + paginare + căutare
src/files.js    — upload multipart (multer), download binar
src/errors.js   — forma standard de eroare + helperele JSON
```

Decizii idiomatice pentru Node (documentate, ca la fiecare port):

- **Parole**: scrypt din `node:crypto`, cu salt aleator — nu e nevoie de
  bcrypt ca dependență în Node. Stocate ca `scrypt:salt:hash` (base64).
- **JWT**: implementat manual (~40 de linii în `src/auth.js`, ca în
  referința Dart), ca să vezi exact ce este un token: `base64url(header)
  . base64url(payload) . HMAC-SHA256`. Fără `jsonwebtoken`.
- **SQLite**: `node:sqlite` (`DatabaseSync`) din stdlib — sincron, simplu,
  fără compilare nativă. Singurele dependențe npm rămân `express` și
  `multer` (parsarea multipart e singurul loc unde o bibliotecă chiar se
  merită).

## Adaugă-ți propria entitate

`src/notes.js` este șablonul — copiază-l:

1. Adaugă un `CREATE TABLE` pentru entitatea ta în `src/db.js` (cu o
   coloană `user_id` dacă aparține unui utilizator).
2. Copiază `src/notes.js` în, de exemplu, `src/recipes.js`; redenumește
   tabelul și câmpurile JSON.
3. Înregistrează noile rute în `server.js`, lângă cele `/notes` (pune
   `requireAuth` înaintea handler-ului).
4. Repornește, testează cu `curl` sau din aplicația ta Flutter, apoi
   rulează din nou suita de conformitate ca să confirmi că contractul de
   bază încă trece.
