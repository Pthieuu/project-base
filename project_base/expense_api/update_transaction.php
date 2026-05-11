<?php

header("Content-Type: application/json");

$conn = new mysqli("localhost", "root", "", "ai_expense_manager");

if ($conn->connect_error) {
    echo json_encode(["status" => "db_error"]);
    exit();
}

$data = json_decode(file_get_contents("php://input"), true);

if (!$data) {
    echo json_encode(["status" => "no_data"]);
    exit();
}

$required = ["id", "user_id", "description", "category", "account", "amount", "is_expense", "notes", "date"];
foreach ($required as $key) {
    if (!isset($data[$key])) {
        echo json_encode(["status" => "missing_field", "message" => "Missing {$key}"]);
        exit();
    }
}

$stmt = $conn->prepare(
    "UPDATE transactions
     SET description = ?, category = ?, account = ?, amount = ?, is_expense = ?, notes = ?, date = ?
     WHERE id = ? AND user_id = ?"
);

$stmt->bind_param(
    "sssdissii",
    $data["description"],
    $data["category"],
    $data["account"],
    $data["amount"],
    $data["is_expense"],
    $data["notes"],
    $data["date"],
    $data["id"],
    $data["user_id"]
);

if ($stmt->execute()) {
    echo json_encode(["status" => "success"]);
} else {
    echo json_encode(["status" => "error", "message" => $stmt->error]);
}

?>
