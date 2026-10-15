<?php

function geminiModel(bool $vision = false): string
{
    return trim(getenv($vision ? "GEMINI_VISION_MODEL" : "GEMINI_MODEL") ?: "gemini-3.5-flash-lite");
}

function buildGeminiContents(array $history, string $message): array
{
    $contents = [];
    foreach (array_slice($history, -8) as $turn) {
        if (!is_array($turn) || !is_string($turn["text"] ?? null)) {
            continue;
        }
        $text = trim($turn["text"]);
        if ($text !== "") {
            $contents[] = [
                "role" => !empty($turn["is_user"]) ? "user" : "model",
                "parts" => [["text" => $text]]
            ];
        }
    }
    $contents[] = ["role" => "user", "parts" => [["text" => $message]]];
    return $contents;
}

function geminiFailure(int $status, string $message): array
{
    return ["status_code" => $status, "message" => $message, "text" => ""];
}

function parseGeminiResponse(int $status, string $body): array
{
    // Do not expose raw provider responses: they can include request details.
    if ($status !== 200) {
        return match ($status) {
            400, 401, 403 => geminiFailure(503, "Gemini từ chối yêu cầu. Kiểm tra API key, quyền truy cập và cấu hình model ở backend."),
            404 => geminiFailure(503, "Không tìm thấy model Gemini. Kiểm tra GEMINI_MODEL hoặc GEMINI_VISION_MODEL."),
            429 => geminiFailure(429, "Gemini đã đạt giới hạn yêu cầu hoặc hết hạn mức. Kiểm tra quota và thử lại sau."),
            default => geminiFailure(503, "Dịch vụ Gemini tạm thời không khả dụng. Vui lòng thử lại sau.")
        };
    }
    $data = json_decode($body, true);
    $candidate = is_array($data) ? ($data["candidates"][0] ?? null) : null;
    if (!is_array($candidate) || ($candidate["finishReason"] ?? "") !== "STOP") {
        return geminiFailure(502, "Gemini không trả về câu trả lời hoàn chỉnh. Hãy thử lại với nội dung ngắn hơn hoặc ảnh rõ hơn.");
    }
    $text = "";
    foreach ($candidate["content"]["parts"] ?? [] as $part) {
        if (is_array($part) && empty($part["thought"]) && is_string($part["text"] ?? null)) {
            $text .= $part["text"];
        }
    }
    if (trim($text) === "") {
        return geminiFailure(502, "Gemini không trả về nội dung hợp lệ.");
    }
    return ["status_code" => 200, "message" => "", "text" => trim($text)];
}

function callGemini(string $model, array $payload): array
{
    $key = trim(getenv("GEMINI_API_KEY") ?: "");
    if ($key === "") {
        return geminiFailure(503, "Chưa cấu hình Gemini API key. Điền GEMINI_API_KEY trong expense_api/.env.gemini.");
    }
    if (!preg_match('/^[a-zA-Z0-9._-]+$/', $model)) {
        return geminiFailure(503, "Tên model Gemini không hợp lệ.");
    }
    $body = json_encode($payload, JSON_UNESCAPED_UNICODE);
    if ($body === false) {
        return geminiFailure(400, "Nội dung gửi đến Gemini không hợp lệ.");
    }
    $ch = curl_init("https://generativelanguage.googleapis.com/v1beta/models/" . rawurlencode($model) . ":generateContent");
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => ["Content-Type: application/json", "x-goog-api-key: " . $key],
        CURLOPT_POSTFIELDS => $body,
        CURLOPT_CONNECTTIMEOUT => 10,
        CURLOPT_TIMEOUT => 120
    ]);
    $response = curl_exec($ch);
    $status = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    if ($response === false) {
        return geminiFailure(503, "Không kết nối được Gemini. Kiểm tra kết nối Internet của backend.");
    }
    return parseGeminiResponse($status, $response);
}
