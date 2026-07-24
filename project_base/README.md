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
- `OLLAMA_BASE_URL`, `OLLAMA_MODEL`

Run the session migration once before signing in:

```bash
/Applications/XAMPP/bin/mysql \
  -h "$DB_HOST" \
  -P "$DB_PORT" \
  -u "$DB_USER" \
  "$DB_NAME" \
  < expense_api/session_migration.sql
```
