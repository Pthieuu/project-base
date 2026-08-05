<?php

header("Content-Type: application/json; charset=utf-8");
require_once dirname(__DIR__, 2) . "/bootstrap/db.php";
require_once dirname(__DIR__, 2) . "/bootstrap/auth.php";
require_once dirname(__DIR__, 2) . "/bootstrap/rate_limit.php";

$userId = requireAuthenticatedUser($conn);
enforceRateLimit($conn, "receipt_ocr", (string)$userId, 10, 900);

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    respondReceiptOcr(405, "Method not allowed");
}

if (!isset($_FILES["receipt"])) {
    respondReceiptOcr(400, "Missing receipt image");
}

$file = $_FILES["receipt"];
if (($file["error"] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    respondReceiptOcr(400, "Receipt upload failed");
}

$fileSize = intval($file["size"] ?? 0);
if ($fileSize <= 0 || $fileSize > 8 * 1024 * 1024) {
    respondReceiptOcr(400, "Receipt image must be smaller than 8 MB");
}

$temporaryPath = (string)($file["tmp_name"] ?? "");
$mimeType = (new finfo(FILEINFO_MIME_TYPE))->file($temporaryPath);
$allowedMimeTypes = ["image/jpeg", "image/png", "image/webp"];
if (!in_array($mimeType, $allowedMimeTypes, true)) {
    respondReceiptOcr(400, "Only JPEG, PNG, and WebP receipts are supported");
}

$imageBytes = file_get_contents($temporaryPath);
if ($imageBytes === false) {
    respondReceiptOcr(400, "Could not read receipt image");
}

$model = envValue("OLLAMA_VISION_MODEL");
$baseUrl = rtrim(envValue("OLLAMA_BASE_URL"), "/");
$today = date("Y-m-d");
$schema = [
    "type" => "object",
    "properties" => [
        "merchant" => ["type" => "string"],
        "amount" => ["type" => "number"],
        "date" => ["type" => "string"],
        "category" => [
            "type" => "string",
            "enum" => [
                "Food & Drink",
                "Shopping",
                "Transport",
                "Coffee",
                "Housing",
                "Entertainment",
                "Health",
                "Other"
            ]
        ],
        "notes" => ["type" => "string"],
        "confidence" => ["type" => "number"],
        "raw_text" => ["type" => "string"],
        "line_items" => [
            "type" => "array",
            "items" => [
                "type" => "object",
                "properties" => [
                    "name" => ["type" => "string"],
                    "quantity" => ["type" => "number"],
                    "unit_price" => ["type" => "number"],
                    "total" => ["type" => "number"]
                ],
                "required" => ["name", "quantity", "unit_price", "total"]
            ]
        ]
    ],
    "required" => [
        "merchant",
        "amount",
        "date",
        "category",
        "notes",
        "confidence",
        "raw_text",
        "line_items"
    ]
];

$prompt = <<<PROMPT
Extract transaction data from this receipt.
Return only data matching the supplied JSON schema.
- merchant: store or merchant name.
- amount: final amount actually paid, taken from labels such as TỔNG CỘNG,
  THÀNH TIỀN, TỔNG TIỀN, TOTAL, or PAYMENT. Do not use a product price,
  subtotal, discount, cash received, or change.
- Vietnamese receipts commonly use dots or spaces as thousands separators.
  For example: "4.899.000", "4 899 000", and "4,899,000" all mean 4899000,
  never 48900. Return amount as a numeric VND value without separators.
- date: receipt date in YYYY-MM-DD. Today is {$today}. Use an empty string if unreadable.
- category: choose the closest allowed category.
- notes: a short useful receipt summary, without repeating merchant or total.
- confidence: a number from 0 to 1 reflecting overall extraction confidence.
- raw_text: important visible receipt text, maximum 500 characters.
- line_items: every readable purchased product. Preserve the complete product
  name. Return quantity, unit_price, and line total as numbers without
  separators. Use an empty array only when no product line is readable.
Before responding, verify the final amount against the printed total and check
that it is plausible relative to the sum of line_items.
Never invent unreadable values. For unreadable amount use 0 and unreadable text fields use an empty string.
PROMPT;

$payload = [
    "model" => $model,
    "messages" => [[
        "role" => "user",
        "content" => $prompt,
        "images" => [base64_encode($imageBytes)]
    ]],
    "stream" => false,
    "format" => $schema,
    "options" => [
        "temperature" => 0
    ]
];

$ch = curl_init($baseUrl . "/api/chat");
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => ["Content-Type: application/json"],
    CURLOPT_POSTFIELDS => json_encode($payload, JSON_UNESCAPED_UNICODE),
    CURLOPT_CONNECTTIMEOUT => 5,
    CURLOPT_TIMEOUT => 120
]);

$responseBody = curl_exec($ch);
$curlError = curl_error($ch);
$statusCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($responseBody === false) {
    respondReceiptOcr(
        503,
        "Could not connect to the configured AI vision service",
        ["detail" => $curlError]
    );
}

$providerResponse = json_decode($responseBody, true);
if ($statusCode !== 200) {
    $message = is_array($providerResponse)
        ? (string)($providerResponse["error"] ?? "AI vision service error")
        : "AI vision service error";
    respondReceiptOcr($statusCode > 0 ? $statusCode : 502, $message);
}

$content = $providerResponse["message"]["content"] ?? "";
$receipt = is_string($content) ? json_decode($content, true) : null;
if (!is_array($receipt)) {
    respondReceiptOcr(502, "AI vision service returned invalid receipt data");
}

$allowedCategories = $schema["properties"]["category"]["enum"];
$merchant = trim((string)($receipt["merchant"] ?? ""));
$amount = max(0, floatval($receipt["amount"] ?? 0));
$date = normalizeReceiptDate((string)($receipt["date"] ?? ""));
$category = trim((string)($receipt["category"] ?? "Other"));
$notes = trim((string)($receipt["notes"] ?? ""));
$confidence = min(1, max(0, floatval($receipt["confidence"] ?? 0)));
$rawTextValue = trim((string)($receipt["raw_text"] ?? ""));
$rawText = function_exists("mb_substr")
    ? mb_substr($rawTextValue, 0, 500)
    : substr($rawTextValue, 0, 500);
$lineItems = normalizeReceiptLineItems($receipt["line_items"] ?? []);

if (!in_array($category, $allowedCategories, true)) {
    $category = "Other";
}

echo json_encode([
    "status" => "success",
    "data" => [
        "merchant" => $merchant,
        "amount" => $amount,
        "date" => $date,
        "category" => $category,
        "notes" => $notes,
        "confidence" => $confidence,
        "raw_text" => $rawText,
        "line_items" => $lineItems
    ],
    "model" => $model
], JSON_UNESCAPED_UNICODE);

function normalizeReceiptDate(string $value): string
{
    $value = trim($value);
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $value)) {
        return "";
    }

    [$year, $month, $day] = array_map("intval", explode("-", $value));
    return checkdate($month, $day, $year) ? $value : "";
}

function normalizeReceiptLineItems(mixed $value): array
{
    if (!is_array($value)) {
        return [];
    }

    $items = [];
    foreach ($value as $item) {
        if (!is_array($item)) {
            continue;
        }

        $name = trim((string)($item["name"] ?? ""));
        if ($name === "") {
            continue;
        }

        $items[] = [
            "name" => $name,
            "quantity" => max(0, floatval($item["quantity"] ?? 0)),
            "unit_price" => max(0, floatval($item["unit_price"] ?? 0)),
            "total" => max(0, floatval($item["total"] ?? 0))
        ];
    }

    return $items;
}

function respondReceiptOcr(
    int $statusCode,
    string $message,
    array $extra = []
): void {
    http_response_code($statusCode);
    echo json_encode(array_merge([
        "status" => "error",
        "message" => $message,
        "status_code" => $statusCode
    ], $extra), JSON_UNESCAPED_UNICODE);
    exit();
}
