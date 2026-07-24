<?php

header("Content-Type: application/json; charset=utf-8");
require_once dirname(__DIR__, 2) . "/bootstrap/db.php";
require_once dirname(__DIR__, 2) . "/bootstrap/auth.php";

$userId = requireAuthenticatedUser($conn);
$data = json_decode(file_get_contents("php://input"), true) ?: [];
$friendshipId = intval($data["friendship_id"] ?? 0);
$action = (string)($data["action"] ?? "");
if (!in_array($action, ["accept", "reject"], true)) {
    echo json_encode(["status" => "error", "message" => "Invalid response"]);
    exit();
}
$status = $action === "accept" ? "accepted" : "rejected";
$stmt = $conn->prepare(
    "UPDATE friendships SET status = ?
     WHERE id = ? AND receiver_id = ? AND status = 'pending'"
);
$stmt->bind_param("sii", $status, $friendshipId, $userId);
$stmt->execute();
if ($stmt->affected_rows < 1) {
    echo json_encode(["status" => "error", "message" => "Invitation not found"]);
    exit();
}
if ($status === "accepted") {
    $streak = $conn->prepare(
        "INSERT IGNORE INTO social_streaks (friendship_id) VALUES (?)"
    );
    $streak->bind_param("i", $friendshipId);
    $streak->execute();
}
echo json_encode(["status" => "success"]);
