<?php

const SESSION_TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30;

function issueAccessToken(mysqli $conn, int $userId): array
{
    $plainToken = bin2hex(random_bytes(32));
    $tokenHash = hash("sha256", $plainToken);
    $expiresAt = date(
        "Y-m-d H:i:s",
        time() + SESSION_TOKEN_TTL_SECONDS
    );

    $stmt = $conn->prepare(
        "INSERT INTO user_sessions (user_id, token_hash, expires_at)
         VALUES (?, ?, ?)"
    );
    if (!$stmt) {
        throw new RuntimeException(
            "Session storage is not ready. Run expense_api/session_migration.sql."
        );
    }
    $stmt->bind_param("iss", $userId, $tokenHash, $expiresAt);

    if (!$stmt->execute()) {
        throw new RuntimeException("Could not create user session");
    }

    return [
        "access_token" => $plainToken,
        "token_type" => "Bearer",
        "expires_at" => $expiresAt
    ];
}

function requireAuthenticatedUser(mysqli $conn): int
{
    $token = readBearerToken();
    if ($token === null) {
        respondUnauthorized("Missing access token");
    }

    $tokenHash = hash("sha256", $token);
    $stmt = $conn->prepare(
        "SELECT user_id
         FROM user_sessions
         WHERE token_hash = ? AND expires_at > NOW()
         LIMIT 1"
    );
    $stmt->bind_param("s", $tokenHash);
    $stmt->execute();
    $result = $stmt->get_result();
    $session = $result->fetch_assoc();

    if (!$session) {
        respondUnauthorized("Invalid or expired access token");
    }

    return intval($session["user_id"]);
}

function revokeCurrentAccessToken(mysqli $conn): void
{
    $token = readBearerToken();
    if ($token === null) {
        return;
    }

    $tokenHash = hash("sha256", $token);
    $stmt = $conn->prepare(
        "DELETE FROM user_sessions WHERE token_hash = ?"
    );
    $stmt->bind_param("s", $tokenHash);
    $stmt->execute();
}

function revokeAllUserSessions(mysqli $conn, int $userId): void
{
    $stmt = $conn->prepare(
        "DELETE FROM user_sessions WHERE user_id = ?"
    );
    $stmt->bind_param("i", $userId);
    $stmt->execute();
}

function readBearerToken(): ?string
{
    $header = $_SERVER["HTTP_AUTHORIZATION"] ?? "";

    if ($header === "" && function_exists("getallheaders")) {
        $headers = getallheaders();
        $header = $headers["Authorization"] ??
            $headers["authorization"] ??
            "";
    }

    if (!preg_match('/^Bearer\s+([A-Fa-f0-9]{64})$/', trim($header), $matches)) {
        return null;
    }

    return $matches[1];
}

function respondUnauthorized(string $message): void
{
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "message" => $message,
        "status_code" => 401
    ]);
    exit();
}
