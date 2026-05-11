<?php

header("Content-Type: application/json");

$conn = new mysqli("localhost", "root", "", "ai_expense_manager");

if ($conn->connect_error) {
    echo json_encode(["status" => "db_error"]);
    exit();
}

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || !isset($data["id"]) || !isset($data["user_id"])) {
    echo json_encode(["status" => "missing_fields"]);
    exit();
}

$stmt = $conn->prepare("DELETE FROM transactions WHERE id = ? AND user_id = ?");
$stmt->bind_param("ii", $data["id"], $data["user_id"]);

if ($stmt->execute()) {
    echo json_encode(["status" => "success"]);
} else {
    echo json_encode(["status" => "error", "message" => $stmt->error]);
}

?>
