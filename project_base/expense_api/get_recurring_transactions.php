<?php

header("Content-Type: application/json");
require_once "db.php";
require_once "auth.php";

$userId = requireAuthenticatedUser($conn);

$stmt = $conn->prepare(
    "SELECT id, description, category, account, amount, is_expense, notes, frequency, next_run_date, is_active
     FROM recurring_transactions
     WHERE user_id = ?
     ORDER BY is_active DESC, next_run_date ASC"
);
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();

$items = [];
while ($row = $result->fetch_assoc()) {
    $items[] = $row;
}

echo json_encode(["status" => "success", "data" => $items]);
