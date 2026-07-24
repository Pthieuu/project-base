<?php

header("Content-Type: application/json");
require_once "db.php";
require_once "auth.php";

$data = json_decode(file_get_contents("php://input"), true) ?: [];
$userId = requireAuthenticatedUser($conn);
$name = trim($data["name"] ?? "");
$email = trim($data["email"] ?? "");

if ($name === "" || $email === "") {
    echo json_encode(["status" => "error", "message" => "Missing profile data"]);
    exit();
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(["status" => "error", "message" => "Invalid email"]);
    exit();
}

$check = $conn->prepare("SELECT id FROM users WHERE email = ? AND id <> ?");
$check->bind_param("si", $email, $userId);
$check->execute();
$existing = $check->get_result();

if ($existing->num_rows > 0) {
    echo json_encode(["status" => "error", "message" => "Email already exists"]);
    exit();
}

$stmt = $conn->prepare("UPDATE users SET name = ?, email = ? WHERE id = ?");
$stmt->bind_param("ssi", $name, $email, $userId);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "name" => $name, "email" => $email]);
} else {
    echo json_encode(["status" => "error", "message" => $stmt->error]);
}
