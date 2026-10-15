<?php
require_once __DIR__ . "/../expense_api/bootstrap/gemini.php";
function check(bool $ok, string $label): void {
    if (!$ok) { throw new RuntimeException($label); }
}
$reply = json_encode(["candidates" => [[
    "finishReason" => "STOP",
    "content" => ["parts" => [["text" => "private", "thought" => true], ["text" => "Hello"], ["text" => " world"]]]
]]]);
check(parseGeminiResponse(200, $reply)["text"] === "Hello world", "Only visible text");
foreach (["MAX_TOKENS", "SAFETY"] as $reason) {
    check(parseGeminiResponse(200, str_replace("STOP", $reason, $reply))["status_code"] === 502, "Reject incomplete response");
}
foreach (["{}", "not json", '{"promptFeedback":{"blockReason":"SAFETY"}}'] as $body) {
    check(parseGeminiResponse(200, $body)["status_code"] === 502, "Reject absent candidate");
}
foreach ([400, 401, 403, 404, 429, 500] as $status) {
    $result = parseGeminiResponse($status, '{"error":{"message":"secret"}}');
    check($result["status_code"] === ($status === 429 ? 429 : 503), "Provider error mapping");
    check(!str_contains($result["message"], "secret"), "No provider details leaked");
}
$contents = buildGeminiContents([null, ["text" => ""], ["text" => "Hi", "is_user" => true], ["text" => "Hello", "is_user" => false]], "Now");
check(array_column($contents, "role") === ["user", "model", "user"], "Conversation roles");
putenv("GEMINI_API_KEY=");
check(callGemini("test", [])["status_code"] === 503, "Missing key handled without network");
echo "Gemini checks passed\n";
