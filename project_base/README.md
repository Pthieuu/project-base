# project_base

Flutter personal finance app with a PHP API and an Ollama-compatible AI
service.

## Local API configuration

Copy the local XAMPP/Ollama environment template. Update any value that differs
on your machine, especially the database password:

```bash
cp expense_api/.env.example expense_api/.env
```

The real `.env` file is ignored by Git and must never be committed. The local
PHP API loads this file automatically:

```bash
php -S 127.0.0.1:8000 -t expense_api
```

Environment variables configured by a production host take precedence over
values in the local `.env` file.

Required variables:

- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- `OLLAMA_BASE_URL`, `OLLAMA_MODEL`, `OLLAMA_VISION_MODEL`

Install the configured vision model once before scanning receipts:

```bash
ollama pull gemma3:4b
```

Run the session migration once before signing in:

```bash
/Applications/XAMPP/bin/mysql \
  -h "$DB_HOST" \
  -P "$DB_PORT" \
  -u "$DB_USER" \
  "$DB_NAME" \
  < expense_api/database/session_migration.sql
```

## PWA

The Flutter web target is configured as an installable PWA. Build it with the
public HTTPS URL of the PHP API:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://example.com/expense_api/
```

Deploy the contents of `build/web` to an HTTPS host such as Cloudflare Pages,
Netlify, Vercel, or Firebase Hosting. The API must also be publicly reachable
over HTTPS; `127.0.0.1` on an iPhone refers to the phone itself.

To install on iPhone:

1. Open the deployed URL in Safari (a QR code may point to this URL).
2. Tap **Share**.
3. Choose **Add to Home Screen**.
4. Tap **Add**.

When deploying below a URL subpath, build with a matching base path:

```bash
flutter build web --release \
  --base-href=/expense-app/ \
  --dart-define=API_BASE_URL=https://example.com/expense_api/
```

### Temporary HTTPS test with ngrok

Build the frontend with the same-origin API path:

```bash
flutter build web --release --dart-define=API_BASE_URL=/api/
```

Serve only the compiled frontend and approved PHP API entrypoints:

```bash
php -S 127.0.0.1:8083 -t build/web tool/pwa_router.php
```

In another terminal, expose the gateway:

```bash
ngrok http 8083
```

Open the HTTPS forwarding URL on iPhone in Safari, then use **Share** →
**Add to Home Screen**. MySQL and Ollama still run locally on the Mac.
