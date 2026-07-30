<?php

declare(strict_types=1);

header("Content-Type: application/json; charset=utf-8");
require_once dirname(__DIR__, 2) . "/bootstrap/db.php";
require_once dirname(__DIR__, 2) . "/bootstrap/auth.php";

$email = strtolower(trim((string)($_POST["email"] ?? "")));
$token = strtolower(trim((string)($_POST["token"] ?? "")));
$password = (string)($_POST["password"] ?? "");

if (
    !filter_var($email, FILTER_VALIDATE_EMAIL) ||
    !preg_match('/^[a-f0-9]{64}$/', $token) ||
    strlen($password) < 8 ||
    strlen($password) > 128
) {
    http_response_code(422);
    echo json_encode(["status" => "invalid_data"]);
    exit();
}

$stmt = $conn->prepare(
    "SELECT prt.id, prt.user_id, prt.token_hash
     FROM password_reset_tokens prt
     INNER JOIN users u ON u.id = prt.user_id
     WHERE u.email = ? AND prt.expires_at > NOW()
     LIMIT 1"
);
$stmt->bind_param("s", $email);
$stmt->execute();
$reset = $stmt->get_result()->fetch_assoc();

if (!$reset || !hash_equals($reset["token_hash"], hash("sha256", $token))) {
    http_response_code(400);
    echo json_encode(["status" => "invalid_or_expired_token"]);
    exit();
}

$passwordHash = password_hash($password, PASSWORD_DEFAULT);
$userId = intval($reset["user_id"]);
$resetId = intval($reset["id"]);

$conn->begin_transaction();
try {
    $update = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
    $update->bind_param("si", $passwordHash, $userId);
    $update->execute();

    revokeAllUserSessions($conn, $userId);

    $delete = $conn->prepare("DELETE FROM password_reset_tokens WHERE id = ?");
    $delete->bind_param("i", $resetId);
    $delete->execute();

    $conn->commit();
    echo json_encode(["status" => "success"]);
} catch (Throwable $error) {
    $conn->rollback();
    error_log("Password reset failed: " . $error->getMessage());
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Password reset failed"]);
}
