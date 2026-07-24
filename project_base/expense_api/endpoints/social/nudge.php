<?php

header("Content-Type: application/json; charset=utf-8");
require_once dirname(__DIR__, 2) . "/bootstrap/db.php";
require_once dirname(__DIR__, 2) . "/bootstrap/auth.php";
require_once dirname(__DIR__, 2) . "/bootstrap/social_streaks.php";

$userId = requireAuthenticatedUser($conn);
$data = json_decode(file_get_contents("php://input"), true) ?: [];
$streakId = intval($data["streak_id"] ?? 0);
$streak = requireStreakMember($conn, $streakId, $userId);
$receiverId = intval($streak["requester_id"]) === $userId
    ? intval($streak["receiver_id"])
    : intval($streak["requester_id"]);
$today = date("Y-m-d");
$stmt = $conn->prepare(
    "INSERT IGNORE INTO streak_nudges
     (streak_id, sender_id, receiver_id, nudge_date)
     VALUES (?, ?, ?, ?)"
);
$stmt->bind_param("iiis", $streakId, $userId, $receiverId, $today);
$stmt->execute();
echo json_encode([
    "status" => "success",
    "sent" => $stmt->affected_rows > 0
]);
