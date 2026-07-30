<?php

require_once __DIR__ . "/config.php";

$appEnvironment = getenv("APP_ENV") ?: "production";
$requestOrigin = $_SERVER["HTTP_ORIGIN"] ?? "";
$allowedOrigin = getenv("CORS_ALLOWED_ORIGIN") ?: "";
if ($appEnvironment === "development") {
    header("Access-Control-Allow-Origin: *");
} elseif (
    $allowedOrigin !== "" &&
    $requestOrigin !== "" &&
    hash_equals($allowedOrigin, $requestOrigin)
) {
    header("Access-Control-Allow-Origin: {$allowedOrigin}");
    header("Vary: Origin");
}
header("Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Authorization, Content-Type, Accept");
header("Access-Control-Max-Age: 86400");

if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") {
    http_response_code(204);
    exit();
}

$host = envValue("DB_HOST");
$portValue = envValue("DB_PORT");
$database = envValue("DB_NAME");
$user = envValue("DB_USER");
$password = envValue("DB_PASSWORD", true);

if (!ctype_digit($portValue)) {
    throw new RuntimeException("DB_PORT must be a valid number");
}

$conn = new mysqli(
    $host,
    $user,
    $password,
    $database,
    intval($portValue)
);

if ($conn->connect_error) {
    throw new RuntimeException("Could not connect to the database");
}

$conn->set_charset("utf8mb4");
