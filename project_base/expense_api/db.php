<?php

require_once __DIR__ . "/config.php";

// Flutter Web and the API run on different origins during development.
// Authentication uses bearer tokens instead of browser cookies, so allowing
// cross-origin API requests does not expose a credentialed session.
header("Access-Control-Allow-Origin: *");
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
