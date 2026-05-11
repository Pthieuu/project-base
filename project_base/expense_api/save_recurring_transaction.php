<?php

header("Content-Type: application/json");
require_once "db.php";

$data = json_decode(file_get_contents("php://input"), true) ?: [];
$userId = intval($data["user_id"] ?? 0);
$id = intval($data["id"] ?? 0);
$description = trim($data["description"] ?? "");
$category = trim($data["category"] ?? "");
$account = trim($data["account"] ?? "Main Card");
$amount = floatval($data["amount"] ?? 0);
$isExpense = intval($data["is_expense"] ?? 1);
$notes = trim($data["notes"] ?? "");
$frequency = trim($data["frequency"] ?? "monthly");
$nextRunDate = trim($data["next_run_date"] ?? "");
$isActive = intval($data["is_active"] ?? 1);

if ($userId <= 0 || $description === "" || $category === "" || $amount <= 0 || $nextRunDate === "") {
    echo json_encode(["status" => "error", "message" => "Missing recurring transaction data"]);
    exit();
}

if (!in_array($frequency, ["daily", "weekly", "monthly"], true)) {
    $frequency = "monthly";
}

if ($id > 0) {
    $stmt = $conn->prepare(
        "UPDATE recurring_transactions
         SET description = ?, category = ?, account = ?, amount = ?, is_expense = ?, notes = ?, frequency = ?, next_run_date = ?, is_active = ?
         WHERE id = ? AND user_id = ?"
    );
    $stmt->bind_param(
        "sssdisssiii",
        $description,
        $category,
        $account,
        $amount,
        $isExpense,
        $notes,
        $frequency,
        $nextRunDate,
        $isActive,
        $id,
        $userId
    );
} else {
    $stmt = $conn->prepare(
        "INSERT INTO recurring_transactions
         (user_id, description, category, account, amount, is_expense, notes, frequency, next_run_date, is_active)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    );
    $stmt->bind_param(
        "isssdisssi",
        $userId,
        $description,
        $category,
        $account,
        $amount,
        $isExpense,
        $notes,
        $frequency,
        $nextRunDate,
        $isActive
    );
}

if ($stmt->execute()) {
    echo json_encode(["status" => "success"]);
} else {
    echo json_encode(["status" => "error", "message" => $stmt->error]);
}

