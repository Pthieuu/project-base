<?php

declare(strict_types=1);

header("Content-Type: application/json; charset=utf-8");

try {
    require_once dirname(__DIR__) . "/bootstrap/db.php";
    if ($conn->query("SELECT 1") === false) {
        throw new RuntimeException("Database health check failed");
    }
    echo json_encode(["status" => "ok"]);
} catch (Throwable $error) {
    error_log("Health check failed: " . $error->getMessage());
    http_response_code(503);
    echo json_encode(["status" => "unavailable"]);
}
