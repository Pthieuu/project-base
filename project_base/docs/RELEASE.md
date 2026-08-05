# Release checklist

## Automated gate

Every item below must pass on the release commit:

```bash
flutter analyze
flutter test
flutter build web --release --dart-define=API_BASE_URL=/api/
composer validate --strict --working-dir=expense_api
composer audit --working-dir=expense_api --locked --no-interaction
php tests/release_guard.php
docker compose --env-file .env.production -f compose.prod.yaml config -q
docker compose --env-file .env.production -f compose.prod.yaml build web api
```

The same code-quality and migration checks run in GitHub Actions.

## Production web deployment

1. Replace every sample secret in `.env.production` with independently generated values.
2. Set the SMTP sender and verify password-reset delivery.
3. Put an HTTPS reverse proxy/CDN in front of the application.
4. Publish the finalized privacy policy and support contact.
5. Create and verify a database backup before upgrading.
6. Deploy with `docker compose up --build -d`; do not use `compose start` as a deployment command.
7. Verify `docker compose ps`, `/api/endpoints/health.php`, login, transaction CRUD, password reset, AI chat, and receipt OCR.
8. Test database restore in a separate environment before accepting production traffic.

Back up the production database with:

```bash
./scripts/backup-database.sh
```

Backups contain personal financial data. Encrypt them, keep them outside the application server, apply a retention policy, and restrict access.

## Android/iOS store release

- Increment `version` and build number in `pubspec.yaml` for every store submission.
- Create the Android upload keystore and `android/key.properties`; release builds fail clearly when it is absent.
- Select the Apple Developer Team and validate signing in Xcode.
- Replace screenshots, descriptions, support URL, and privacy-policy URL with final public values.
- Complete Play Console Data safety and App Store privacy disclosures based on the deployed infrastructure.
- Test account deletion/data deletion procedures before publishing.

Signing keys, Apple Team IDs, domains, and legal contact details must not be committed to this repository.
