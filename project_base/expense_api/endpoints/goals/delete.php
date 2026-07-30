<?php

header("Content-Type: application/json; charset=utf-8");
require_once dirname(__DIR__, 2) . "/bootstrap/db.php";
require_once dirname(__DIR__, 2) . "/bootstrap/auth.php";

$data = json_decode(file_get_contents("php://input"), true) ?: [];
$goalId = intval($data["id"] ?? 0);
$userId = requireAuthenticatedUser($conn);

if ($goalId <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing goal id"
    ]);
    exit();
}

$stmt = $conn->prepare(
    "DELETE FROM saving_goals WHERE id = ? AND user_id = ?"
);
$stmt->bind_param("ii", $goalId, $userId);

if (!$stmt->execute()) {
    echo json_encode([
        "status" => "error",
        "message" => "Could not delete goal"
    ]);
    exit();
}

if ($stmt->affected_rows === 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Saving goal not found"
    ]);
    exit();
}

echo json_encode(["status" => "success"]);
