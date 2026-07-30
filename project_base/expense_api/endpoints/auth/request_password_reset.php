<?php

declare(strict_types=1);

header("Content-Type: application/json; charset=utf-8");
require_once dirname(__DIR__, 2) . "/bootstrap/db.php";
require_once dirname(__DIR__, 2) . "/bootstrap/mailer.php";

$email = strtolower(trim((string)($_POST["email"] ?? "")));
$genericResponse = [
    "status" => "accepted",
    "message" => "If the account exists, reset instructions have been sent."
];

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode($genericResponse);
    exit();
}

$stmt = $conn->prepare("SELECT id FROM users WHERE email = ? LIMIT 1");
$stmt->bind_param("s", $email);
$stmt->execute();
$user = $stmt->get_result()->fetch_assoc();

if (!$user) {
    echo json_encode($genericResponse);
    exit();
}

$userId = intval($user["id"]);
$recent = $conn->prepare(
    "SELECT created_at FROM password_reset_tokens
     WHERE user_id = ? AND created_at > DATE_SUB(NOW(), INTERVAL 60 SECOND)"
);
$recent->bind_param("i", $userId);
$recent->execute();
if ($recent->get_result()->fetch_assoc()) {
    echo json_encode($genericResponse);
    exit();
}

$token = bin2hex(random_bytes(32));
$tokenHash = hash("sha256", $token);
$expiresAt = date("Y-m-d H:i:s", time() + 15 * 60);
$save = $conn->prepare(
    "INSERT INTO password_reset_tokens (user_id, token_hash, expires_at)
     VALUES (?, ?, ?)
     ON DUPLICATE KEY UPDATE
       token_hash = VALUES(token_hash),
       expires_at = VALUES(expires_at),
       created_at = CURRENT_TIMESTAMP"
);
$save->bind_param("iss", $userId, $tokenHash, $expiresAt);
$save->execute();

$appEnvironment = getenv("APP_ENV") ?: "production";
if ($appEnvironment === "development") {
    // Local Docker has no mail transport. Returning the token is strictly
    // limited to development so the flow remains testable.
    $genericResponse["reset_token"] = $token;
} elseif (!sendPasswordResetEmail($email, $token)) {
    error_log("Password reset mail delivery failed");
    http_response_code(503);
    echo json_encode([
        "status" => "unavailable",
        "message" => "Password reset is temporarily unavailable."
    ]);
    exit();
}

echo json_encode($genericResponse);
