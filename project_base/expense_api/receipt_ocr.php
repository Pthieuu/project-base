<?php

header("Content-Type: application/json; charset=utf-8");
require_once "db.php";
require_once "auth.php";

requireAuthenticatedUser($conn);

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
        "raw_text" => ["type" => "string"]
    ],
    "required" => [
        "merchant",
        "amount",
        "date",
        "category",
        "notes",
        "confidence",
        "raw_text"
    ]
];

$prompt = <<<PROMPT
Extract transaction data from this receipt.
Return only data matching the supplied JSON schema.
- merchant: store or merchant name.
- amount: final amount actually paid. Use the numeric VND value without currency symbols or separators.
- date: receipt date in YYYY-MM-DD. Today is {$today}. Use an empty string if unreadable.
- category: choose the closest allowed category.
- notes: a short useful receipt summary, without repeating merchant or total.
- confidence: a number from 0 to 1 reflecting overall extraction confidence.
- raw_text: important visible receipt text, maximum 500 characters.
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
        "raw_text" => $rawText
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
