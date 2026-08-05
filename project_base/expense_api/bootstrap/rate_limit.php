<?php

declare(strict_types=1);

function enforceRateLimit(
    mysqli $conn,
    string $action,
    string $subject,
    int $maximumAttempts,
    int $windowSeconds
): void {
    $subjectHash = hash("sha256", $subject);
    $cleanup = $conn->prepare(
        "DELETE FROM api_rate_limits WHERE attempted_at < DATE_SUB(NOW(), INTERVAL 1 DAY)"
    );
    $cleanup->execute();

    $count = $conn->prepare(
        "SELECT COUNT(*) AS attempts FROM api_rate_limits
         WHERE action_name = ? AND subject_hash = ?
           AND attempted_at >= DATE_SUB(NOW(), INTERVAL ? SECOND)"
    );
    $count->bind_param("ssi", $action, $subjectHash, $windowSeconds);
    $count->execute();
    $attempts = intval($count->get_result()->fetch_assoc()["attempts"] ?? 0);

    if ($attempts >= $maximumAttempts) {
        http_response_code(429);
        header("Retry-After: {$windowSeconds}");
        header("Content-Type: application/json; charset=utf-8");
        echo json_encode([
            "status" => "rate_limited",
            "message" => "Too many requests. Try again later.",
            "status_code" => 429,
        ]);
        exit();
    }

    $record = $conn->prepare(
        "INSERT INTO api_rate_limits (action_name, subject_hash) VALUES (?, ?)"
    );
    $record->bind_param("ss", $action, $subjectHash);
    $record->execute();
}
