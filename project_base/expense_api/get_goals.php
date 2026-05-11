<?php

header("Content-Type: application/json");
require_once "db.php";

$data = json_decode(file_get_contents("php://input"), true) ?: [];
$userId = intval($data["user_id"] ?? 0);

if ($userId <= 0) {
    echo json_encode(["status" => "error", "message" => "Missing user_id"]);
    exit();
}

$stmt = $conn->prepare(
    "SELECT id, title, target_amount, current_amount, target_date, note, is_completed
     FROM saving_goals
     WHERE user_id = ?
     ORDER BY is_completed ASC, created_at DESC"
);
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();

$goals = [];
while ($row = $result->fetch_assoc()) {
    $goals[] = $row;
}

echo json_encode(["status" => "success", "data" => $goals]);

