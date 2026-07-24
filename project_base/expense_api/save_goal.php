<?php

header("Content-Type: application/json");
require_once "db.php";
require_once "auth.php";

$data = json_decode(file_get_contents("php://input"), true) ?: [];
$userId = requireAuthenticatedUser($conn);
$id = intval($data["id"] ?? 0);
$title = trim($data["title"] ?? "");
$targetAmount = floatval($data["target_amount"] ?? 0);
$currentAmount = floatval($data["current_amount"] ?? 0);
$targetDate = trim($data["target_date"] ?? "");
$note = trim($data["note"] ?? "");
$isCompleted = intval($data["is_completed"] ?? 0);
$targetDateValue = $targetDate === "" ? null : $targetDate;

if ($title === "" || $targetAmount <= 0) {
    echo json_encode(["status" => "error", "message" => "Missing goal data"]);
    exit();
}

if ($currentAmount >= $targetAmount) {
    $isCompleted = 1;
}

if ($id > 0) {
    $stmt = $conn->prepare(
        "UPDATE saving_goals
         SET title = ?, target_amount = ?, current_amount = ?, target_date = ?, note = ?, is_completed = ?
         WHERE id = ? AND user_id = ?"
    );
    $stmt->bind_param(
        "sddssiii",
        $title,
        $targetAmount,
        $currentAmount,
        $targetDateValue,
        $note,
        $isCompleted,
        $id,
        $userId
    );
} else {
    $stmt = $conn->prepare(
        "INSERT INTO saving_goals (user_id, title, target_amount, current_amount, target_date, note, is_completed)
         VALUES (?, ?, ?, ?, ?, ?, ?)"
    );
    $stmt->bind_param(
        "isddssi",
        $userId,
        $title,
        $targetAmount,
        $currentAmount,
        $targetDateValue,
        $note,
        $isCompleted
    );
}

if ($stmt->execute()) {
    echo json_encode(["status" => "success"]);
} else {
    echo json_encode(["status" => "error", "message" => $stmt->error]);
}
