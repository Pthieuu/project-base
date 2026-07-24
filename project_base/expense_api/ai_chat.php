<?php

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
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

require_once "db.php";
require_once "auth.php";
requireAuthenticatedUser($conn);

$input = json_decode(file_get_contents("php://input"), true);
if (!is_array($input)) {
    respond(400, [
        "status" => "error",
        "message" => "JSON không hợp lệ.",
        "status_code" => 400
    ]);
}

$message = trim((string)($input["message"] ?? ""));
$language = normalizeLanguage((string)($input["language"] ?? "vi"));
$history = is_array($input["history"] ?? null) ? $input["history"] : [];
$transactions = is_array($input["transactions"] ?? null) ? $input["transactions"] : [];

if ($message === "") {
    respond(400, [
        "status" => "error",
        "message" => "Thiếu nội dung câu hỏi.",
        "status_code" => 400
    ]);
}

$model = envValue("OLLAMA_MODEL");
$baseUrl = rtrim(envValue("OLLAMA_BASE_URL"), "/");
$messages = buildOllamaMessages(buildInstructions($transactions, $language), $history, $message);
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

function normalizeLanguage(string $language): string
{
    $language = strtolower(trim($language));
    if (in_array($language, ["en", "english"], true)) {
        return "en";
    }
    if (in_array($language, ["ja", "jp", "japanese"], true)) {
        return "ja";
    }
    return "vi";
}

function languageName(string $language): string
{
    if ($language === "en") {
        return "English";
    }
    if ($language === "ja") {
        return "Japanese";
    }
    return "Vietnamese";
}

function localizedActionMessage(string $language): string
{
    if ($language === "en") {
        return "I separated the items below. Please review and confirm to save.";
    }
    if ($language === "ja") {
        return "下の項目に分けました。内容を確認して保存してください。";
    }
    return "Mình đã tách thành các mục bên dưới, bạn kiểm tra rồi xác nhận để lưu.";
}

function localizedScopeReply(string $language): string
{
    if ($language === "en") {
        return "I only help with personal finance topics. Please ask me about spending, income, budget, savings, or transactions.";
    }
    if ($language === "ja") {
        return "個人の家計管理に関する内容のみサポートします。支出、収入、予算、貯蓄、取引について質問してください。";
    }
    return "Mình chỉ hỗ trợ các câu hỏi liên quan đến quản lý tài chính cá nhân. Bạn hỏi mình về chi tiêu, thu nhập, ngân sách, tiết kiệm hoặc giao dịch nhé.";
}

function buildInstructions(array $transactions, string $language): string
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
    $totalIncome = 0.0;
    $totalExpense = 0.0;
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

        if ($isExpense) {
            $totalExpense += $amount;
        } else {
            $totalIncome += $amount;
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
    $totalBalance = $totalIncome - $totalExpense;

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
    $languageName = languageName($language);
    $scopeReply = localizedScopeReply($language);
    $actionMessage = localizedActionMessage($language);

    return <<<PROMPT
Bạn là trợ lý AI trong app quản lý chi tiêu cá nhân.
Luôn trả lời bằng {$languageName}, tự nhiên như đang chat thật với người dùng.
Chỉ trả lời các nội dung liên quan đến quản lý tài chính cá nhân: chi tiêu, thu nhập, giao dịch, ngân sách, tiết kiệm, mục tiêu tài chính, dự đoán chi tiêu, hóa đơn, nợ/vay hoặc nhập dữ liệu tài chính vào app.
Nếu người dùng hỏi ngoài phạm vi tài chính cá nhân, hãy từ chối ngắn gọn bằng đúng câu: "{$scopeReply}"
Khi câu hỏi liên quan đến tài chính, hãy dùng dữ liệu tài chính bên dưới để phân tích.
Nếu người dùng hỏi "tổng", "từ trước đến nay", "đã chi bao nhiêu" mà không nói tháng nào, hãy dùng Tổng chi tất cả.
Nếu người dùng hỏi "tháng này", "hiện tại trong tháng", hãy dùng Tổng chi tháng này.
Trả lời đúng câu hỏi trước, sau đó mới giải thích bằng dữ liệu nếu cần.
Giữ mạch hội thoại từ lịch sử chat; đừng trả lời theo mẫu cố định.
Nếu dữ liệu chưa đủ để kết luận, nói rõ là chưa đủ dữ liệu và hỏi/gợi ý người dùng thêm giao dịch.
Không bịa số liệu không có trong dữ liệu. Không nhắc đến backend, Ollama, API key, quota, mock, fallback hay rule.

Khi người dùng muốn bạn nhập/lưu/tạo giúp dữ liệu trong app, KHÔNG trả lời văn bản thường.
Hãy trả về DUY NHẤT một JSON object hợp lệ, không markdown, không giải thích ngoài JSON.
Schema chung:
{
  "type": "action",
  "action": "add_transaction|add_saving_goal|set_budget|add_recurring_transaction",
  "message": "Câu xác nhận ngắn bằng {$languageName}",
  "payload": {}
}

Nếu người dùng yêu cầu thêm/lưu nhiều khoản hoặc nhiều hành động trong cùng một câu, hãy tách thành nhiều action riêng.
KHÔNG gộp nhiều khoản chi vào một payload, KHÔNG tạo một mô tả chung.
Trả về schema nhiều hành động:
{
  "type": "actions",
  "message": "{$actionMessage}",
  "actions": [
    {
      "action": "add_transaction",
      "payload": {}
    }
  ]
}

Payload add_transaction:
{
  "description": "nội dung",
  "category": "Food & Drink|Shopping|Transport|Housing|Entertainment|Salary|Other hoặc category tự suy luận",
  "account": "Main Card hoặc Cash",
  "amount": số tiền VND,
  "is_expense": true nếu chi tiêu, false nếu thu nhập,
  "notes": "",
  "date": "YYYY-MM-DD"
}

Payload add_saving_goal:
{
  "title": "tên mục tiêu",
  "target_amount": số tiền VND,
  "current_amount": số tiền hiện có hoặc 0,
  "target_date": "YYYY-MM-DD hoặc rỗng",
  "note": ""
}

Payload set_budget:
{
  "category": "danh mục",
  "month": "YYYY-MM",
  "monthly_limit": số tiền VND
}

Payload add_recurring_transaction:
{
  "description": "nội dung",
  "category": "danh mục",
  "account": "Main Card hoặc Cash",
  "amount": số tiền VND,
  "is_expense": true nếu chi định kỳ, false nếu thu định kỳ,
  "frequency": "daily|weekly|monthly",
  "next_run_date": "YYYY-MM-DD",
  "notes": ""
}

Nếu thiếu thông tin quan trọng như số tiền hoặc tên mục tiêu, hãy hỏi lại bằng văn bản thường, không tạo JSON.
Quy đổi cách nói tiền Việt: "50k" = 50000, "2 triệu" = 2000000, "8tr" = 8000000.
Nếu người dùng nói "hôm nay", dùng ngày hiện tại theo Asia/Ho_Chi_Minh.

Dữ liệu tài chính người dùng:
- Tháng hiện tại: {$monthText}
- Ngày hiện tại: {$now->format("Y-m-d")}
- Tổng thu tất cả: {$totalIncome}
- Tổng chi tất cả: {$totalExpense}
- Số dư tất cả: {$totalBalance}
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
