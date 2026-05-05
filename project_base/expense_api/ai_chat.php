<?php

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST, OPTIONS");

if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") {
    exit();
}

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    respond(405, [
        "status" => "error",
        "message" => "Method not allowed",
        "status_code" => 405
    ]);
}

$input = json_decode(file_get_contents("php://input"), true);
if (!is_array($input)) {
    respond(400, [
        "status" => "error",
        "message" => "JSON không hợp lệ.",
        "status_code" => 400
    ]);
}

$message = trim((string)($input["message"] ?? ""));
$history = is_array($input["history"] ?? null) ? $input["history"] : [];
$transactions = is_array($input["transactions"] ?? null) ? $input["transactions"] : [];

if ($message === "") {
    respond(400, [
        "status" => "error",
        "message" => "Thiếu nội dung câu hỏi.",
        "status_code" => 400
    ]);
}

$model = getenv("OLLAMA_MODEL") ?: "llama3.2";
$baseUrl = rtrim(getenv("OLLAMA_BASE_URL") ?: "http://127.0.0.1:11434", "/");
$messages = buildOllamaMessages(buildInstructions($transactions), $history, $message);
$result = callOllama($baseUrl, $model, $messages);

if ($result["status_code"] !== 200) {
    respond((int)$result["status_code"], [
        "status" => "error",
        "message" => $result["message"],
        "status_code" => $result["status_code"],
        "provider" => "ollama",
        "model" => $model
    ]);
}

$reply = extractOllamaText($result["data"]);
if ($reply === "") {
    respond(502, [
        "status" => "error",
        "message" => "Ollama không trả về nội dung hợp lệ.",
        "status_code" => 502,
        "provider" => "ollama",
        "model" => $model
    ]);
}

respond(200, [
    "status" => "success",
    "reply" => $reply,
    "provider" => "ollama",
    "model" => $model
]);

function buildOllamaMessages(string $systemPrompt, array $history, string $message): array
{
    $messages = [
        [
            "role" => "system",
            "content" => $systemPrompt
        ]
    ];

    foreach (array_slice($history, -8) as $turn) {
        if (!is_array($turn)) {
            continue;
        }

        $text = trim((string)($turn["text"] ?? ""));
        if ($text === "") {
            continue;
        }

        $messages[] = [
            "role" => !empty($turn["is_user"]) ? "user" : "assistant",
            "content" => $text
        ];
    }

    $messages[] = [
        "role" => "user",
        "content" => $message
    ];

    return $messages;
}

function callOllama(string $baseUrl, string $model, array $messages): array
{
    $payload = [
        "model" => $model,
        "messages" => $messages,
        "stream" => false,
        "options" => [
            "temperature" => 0.7,
            "num_predict" => 1536
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
        return [
            "status_code" => 503,
            "message" => "Chưa kết nối được Ollama local. Hãy chạy `ollama serve` và tải model `{$model}`.",
            "raw" => $curlError,
            "data" => null
        ];
    }

    $data = json_decode($responseBody, true);
    if ($statusCode !== 200) {
        $message = is_array($data) && isset($data["error"])
            ? (string)$data["error"]
            : $responseBody;

        if (str_contains($message, "model") && str_contains($message, "not found")) {
            $message = "Ollama chưa có model `{$model}`. Hãy chạy `ollama pull {$model}`.";
        }

        return [
            "status_code" => $statusCode > 0 ? $statusCode : 502,
            "message" => trim($message) !== "" ? trim($message) : "Ollama local trả lỗi.",
            "raw" => $responseBody,
            "data" => $data
        ];
    }

    return [
        "status_code" => 200,
        "message" => "",
        "raw" => $responseBody,
        "data" => $data
    ];
}

function extractOllamaText(?array $data): string
{
    if (!is_array($data)) {
        return "";
    }

    $content = $data["message"]["content"] ?? "";
    return is_string($content) ? trim($content) : "";
}

function buildInstructions(array $transactions): string
{
    date_default_timezone_set("Asia/Ho_Chi_Minh");

    $now = new DateTimeImmutable("now");
    $currentMonth = $now->format("Y-m");
    $previousMonth = $now->modify("first day of previous month")->format("Y-m");

    usort($transactions, function ($a, $b) {
        return strcmp($b["date"] ?? "", $a["date"] ?? "");
    });

    $currentIncome = 0.0;
    $currentExpense = 0.0;
    $previousExpense = 0.0;
    $currentCount = 0;
    $categoryTotals = [];

    foreach ($transactions as $tx) {
        if (!is_array($tx)) {
            continue;
        }

        $date = (string)($tx["date"] ?? "");
        $month = substr($date, 0, 7);
        $amount = (float)($tx["amount"] ?? 0);
        $isExpense = !empty($tx["is_expense"]);
        $category = trim((string)($tx["category"] ?? "Other"));
        if ($category === "") {
            $category = "Other";
        }

        if ($month === $currentMonth) {
            $currentCount++;
            if ($isExpense) {
                $currentExpense += $amount;
                $categoryTotals[$category] = ($categoryTotals[$category] ?? 0) + $amount;
            } else {
                $currentIncome += $amount;
            }
        }

        if ($month === $previousMonth && $isExpense) {
            $previousExpense += $amount;
        }
    }

    arsort($categoryTotals);
    $daysInMonth = (int)$now->format("t");
    $dayOfMonth = max(1, (int)$now->format("j"));
    $predictedExpense = $currentExpense / $dayOfMonth * $daysInMonth;

    $topCategories = [];
    foreach (array_slice($categoryTotals, 0, 5, true) as $category => $amount) {
        $topCategories[] = "- {$category}: {$amount}";
    }

    $recentRows = [];
    foreach (array_slice($transactions, 0, 20) as $tx) {
        if (!is_array($tx)) {
            continue;
        }

        $sign = !empty($tx["is_expense"]) ? "-" : "+";
        $recentRows[] = "- " . ($tx["date"] ?? "") .
            " | " . ($tx["category"] ?? "") .
            " | " . ($tx["description"] ?? "") .
            " | " . $sign . ($tx["amount"] ?? 0);
    }

    $categoryText = empty($topCategories) ? "- Chưa có dữ liệu" : implode("\n", $topCategories);
    $recentText = empty($recentRows) ? "- Chưa có giao dịch" : implode("\n", $recentRows);
    $monthText = $now->format("m/Y");

    return <<<PROMPT
Bạn là trợ lý AI trong app quản lý chi tiêu cá nhân.
Luôn trả lời bằng tiếng Việt, tự nhiên như đang chat thật với người dùng.
Bạn có thể trả lời mọi câu hỏi thông thường của người dùng, không chỉ câu hỏi tài chính.
Khi câu hỏi liên quan đến chi tiêu, hãy dùng dữ liệu tài chính bên dưới để phân tích.
Trả lời đúng câu hỏi trước, sau đó mới giải thích bằng dữ liệu nếu cần.
Giữ mạch hội thoại từ lịch sử chat; đừng trả lời theo mẫu cố định.
Nếu dữ liệu chưa đủ để kết luận, nói rõ là chưa đủ dữ liệu và hỏi/gợi ý người dùng thêm giao dịch.
Không bịa số liệu không có trong dữ liệu. Không nhắc đến backend, Ollama, API key, quota, mock, fallback hay rule.

Dữ liệu tài chính người dùng:
- Tháng hiện tại: {$monthText}
- Tổng thu tháng này: {$currentIncome}
- Tổng chi tháng này: {$currentExpense}
- Tổng chi tháng trước: {$previousExpense}
- Dự đoán chi cuối tháng nếu giữ tốc độ hiện tại: {$predictedExpense}
- Số giao dịch tháng này: {$currentCount}

Danh mục chi lớn nhất tháng này:
{$categoryText}

20 giao dịch gần nhất:
{$recentText}
PROMPT;
}

function respond(int $statusCode, array $data): void
{
    http_response_code($statusCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit();
}

?>
