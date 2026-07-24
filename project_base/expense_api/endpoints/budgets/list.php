<?php

header("Content-Type: application/json");
require_once dirname(__DIR__, 2) . "/bootstrap/db.php";
require_once dirname(__DIR__, 2) . "/bootstrap/auth.php";

$data = json_decode(file_get_contents("php://input"), true) ?: [];
$userId = requireAuthenticatedUser($conn);
$month = trim($data["month"] ?? date("Y-m"));

$stmt = $conn->prepare(
    "SELECT id, category, monthly_limit, month
     FROM category_budgets
     WHERE user_id = ? AND month = ?
     ORDER BY category ASC"
);
$stmt->bind_param("is", $userId, $month);
$stmt->execute();
$result = $stmt->get_result();

$budgets = [];
while ($row = $result->fetch_assoc()) {
    $budgets[] = $row;
}

echo json_encode(["status" => "success", "data" => $budgets]);
