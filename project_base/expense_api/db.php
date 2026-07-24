<?php

require_once __DIR__ . "/config.php";

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
