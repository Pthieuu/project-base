# project_base

Flutter personal finance app with a PHP API and an Ollama-compatible AI
service.

## Chạy toàn bộ dự án bằng Docker Desktop

Docker chạy Flutter Web, PHP API, MySQL và Ollama cùng nhau. Lần đầu tiên, tại
thư mục dự án chạy:

```bash
docker compose up --build
```

Sau khi build hoàn tất, mở <http://localhost:8080>. Để khởi động lại hoặc deploy,
luôn dùng `docker compose up -d`; lệnh này cũng tạo lại container bị thiếu.

Database được lưu trong Docker volume `expense_database`, vì vậy dữ liệu không
mất khi dừng container. Các file SQL chỉ tự động khởi tạo khi volume database
được tạo lần đầu.

Docker tự tải `llama3.2` và `gemma3:4b` vào volume `ollama_models`. Lần chạy đầu
cần chờ tải vài GB trước khi ứng dụng khởi động; những lần sau Docker dùng lại
model đã lưu. Ollama trong Docker chạy bằng CPU trên các máy không cung cấp GPU
cho container nên phản hồi AI có thể chậm hơn Ollama chạy trực tiếp trên máy.

## Production

`compose.yaml` là môi trường development. Không đưa cấu hình này trực tiếp lên
Internet. Bản production dùng PHP-FPM và Nginx, yêu cầu mật khẩu database cùng
thông tin SMTP từ biến môi trường:

```bash
cp .env.production.example .env.production
# Thay toàn bộ giá trị mẫu trong .env.production trước khi tiếp tục.
docker compose --env-file .env.production -f compose.prod.yaml up --build -d
```

Đặt reverse proxy/CDN có HTTPS phía trước cổng ứng dụng. Secure session của bản
web chỉ hoạt động trên HTTPS hoặc localhost.

API tự chạy toàn bộ migration idempotent trên cả database mới và database đã tồn
tại trước khi nhận traffic. Không còn container migration chạy một lần.

Checklist release, backup và các bước ký ứng dụng nằm trong
[`docs/RELEASE.md`](docs/RELEASE.md). Hoàn thiện
[`docs/PRIVACY_POLICY_TEMPLATE.md`](docs/PRIVACY_POLICY_TEMPLATE.md) với thông
tin pháp lý và hạ tầng thực tế trước khi public.

Email quên mật khẩu dùng SMTP qua các biến `SMTP_HOST`, `SMTP_PORT`,
`SMTP_USERNAME`, `SMTP_PASSWORD` và `PASSWORD_RESET_FROM`. Development trả token
trực tiếp để test; production tuyệt đối không trả token trong API.

### Android signing

Application ID là `com.aiexpensemanager.app`. Tạo upload keystore riêng, sao
chép `android/key.properties.example` thành `android/key.properties`, rồi thay
các giá trị mẫu. Keystore và `key.properties` đã được Git bỏ qua và không được
commit. Với iOS, chọn Apple Development Team của bạn trong Xcode trước khi
archive.

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
