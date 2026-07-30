<?php

header("Content-Type: application/json");
require_once dirname(__DIR__, 2) . "/bootstrap/db.php";
require_once dirname(__DIR__, 2) . "/bootstrap/auth.php";

$data = json_decode(file_get_contents("php://input"), true) ?: [];
$userId = requireAuthenticatedUser($conn);
$name = trim($data["name"] ?? "");
$type = trim($data["type"] ?? "expense");
$icon = trim($data["icon"] ?? "wallet");
$color = trim($data["color"] ?? "#1132D4");

if ($name === "") {
    echo json_encode(["status" => "error", "message" => "Missing category data"]);
    exit();
}

if (!in_array($type, ["income", "expense", "both"], true)) {
    $type = "expense";
}

$stmt = $conn->prepare(
    "INSERT INTO categories (user_id, name, icon, color, type)
     VALUES (?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       icon = VALUES(icon),
       color = VALUES(color),
       type = VALUES(type)"
);
$stmt->bind_param("issss", $userId, $name, $icon, $color, $type);

if ($stmt->execute()) {
    echo json_encode(["status" => "success"]);
} else {
    error_log("Category save failed: " . $stmt->error);
    echo json_encode(["status" => "error", "message" => "Could not save category"]);
}
