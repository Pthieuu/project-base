<?php

header("Content-Type: application/json");

require_once "db.php";
require_once "auth.php";
$userId = requireAuthenticatedUser($conn);

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || !isset($data["id"])) {
    echo json_encode(["status" => "missing_fields"]);
    exit();
}

$stmt = $conn->prepare("DELETE FROM transactions WHERE id = ? AND user_id = ?");
$stmt->bind_param("ii", $data["id"], $userId);

if ($stmt->execute() && $stmt->affected_rows > 0) {
    echo json_encode(["status" => "success"]);
} else {
    echo json_encode([
        "status" => "error",
        "message" => $stmt->error ?: "Transaction not found"
    ]);
}
