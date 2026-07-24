<?php

header("Content-Type: application/json");
require_once "db.php";
require_once "auth.php";

$data = json_decode(file_get_contents("php://input"), true) ?: [];
$userId = requireAuthenticatedUser($conn);
$category = trim($data["category"] ?? "");
$month = trim($data["month"] ?? date("Y-m"));
$monthlyLimit = floatval($data["monthly_limit"] ?? 0);

if ($category === "") {
    echo json_encode(["status" => "error", "message" => "Missing budget data"]);
    exit();
}

$stmt = $conn->prepare(
    "INSERT INTO category_budgets (user_id, category, month, monthly_limit)
     VALUES (?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE monthly_limit = VALUES(monthly_limit)"
);
$stmt->bind_param("issd", $userId, $category, $month, $monthlyLimit);

if ($stmt->execute()) {
    echo json_encode(["status" => "success"]);
} else {
    echo json_encode(["status" => "error", "message" => $stmt->error]);
}
