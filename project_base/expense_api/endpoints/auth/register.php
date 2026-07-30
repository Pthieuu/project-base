<?php

declare(strict_types=1);

header("Content-Type: application/json; charset=utf-8");
require_once dirname(__DIR__, 2) . "/bootstrap/db.php";

$name = trim((string)($_POST["name"] ?? ""));
$email = strtolower(trim((string)($_POST["email"] ?? "")));
$password = (string)($_POST["password"] ?? "");

if ($name === "" || $email === "" || $password === "") {
    http_response_code(422);
    echo json_encode(["status" => "empty_fields"]);
    exit();
}

if (strlen($name) > 300 || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(422);
    echo json_encode(["status" => "invalid_data"]);
    exit();
}

if (strlen($password) < 8 || strlen($password) > 128) {
    http_response_code(422);
    echo json_encode(["status" => "weak_password"]);
    exit();
}

$passwordHash = password_hash($password, PASSWORD_DEFAULT);
$stmt = $conn->prepare(
    "INSERT INTO users (name, email, password) VALUES (?, ?, ?)"
);
$stmt->bind_param("sss", $name, $email, $passwordHash);

try {
    $stmt->execute();
    http_response_code(201);
    echo json_encode(["status" => "success"]);
} catch (mysqli_sql_exception $error) {
    if ($error->getCode() === 1062) {
        http_response_code(409);
        echo json_encode(["status" => "email_exists"]);
        exit();
    }

    error_log("Registration failed: " . $error->getMessage());
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Registration failed"]);
}
